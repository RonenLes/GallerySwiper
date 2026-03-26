package com.example.galleryswiper;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import android.app.Activity;
import android.app.PendingIntent;
import android.provider.MediaStore;
import android.content.ContentUris;
import android.database.Cursor;

import androidx.activity.result.IntentSenderRequest;
import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private static final float SWIPE_THRESHOLD = 300f;
    private static final String PREFS_NAME = "GallerySwiperPrefs";
    private static final String PREF_SHOW_INSTRUCTIONS = "show_instructions";

    private Button btnUndo;
    private Button btnDeleteMarked;
    private ImageView imageViewPhoto;
    private View sideIndicatorLeft, sideIndicatorRight;
    private TextView tvProgress;
    private ProgressBar progressBar;
    
    private final ArrayList<Uri> photoUris = new ArrayList<>();
    private final ArrayList<Uri> deleteUris = new ArrayList<>();
    private final ArrayList<Uri> keepUris = new ArrayList<>();
    private final ArrayList<SwipeAction> actionStack = new ArrayList<>();

    private int currentIndex = 0;
    private float downX;

    private final ActivityResultLauncher<PickVisualMediaRequest> pickMedia =
            registerForActivityResult(
                    new ActivityResultContracts.PickMultipleVisualMedia(100),
                    uris -> {
                        if (uris == null || uris.isEmpty()) {
                            Toast.makeText(this, getString(R.string.no_photos_selected), Toast.LENGTH_SHORT).show();
                            return;
                        }
                        setupPhotoList(uris);
                    }
            );

    private final ActivityResultLauncher<String[]> requestPermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestMultiplePermissions(), permissions -> {
                boolean allGranted = true;
                for (Boolean granted : permissions.values()) {
                    if (!granted) {
                        allGranted = false;
                        break;
                    }
                }
                if (allGranted) {
                    scanAllPhotos();
                } else {
                    Toast.makeText(this, getString(R.string.permission_denied), Toast.LENGTH_SHORT).show();
                }
            });

    private final ActivityResultLauncher<IntentSenderRequest> deleteLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartIntentSenderForResult(),
                    result -> {
                        if (result.getResultCode() == Activity.RESULT_OK) {
                            Toast.makeText(this, getString(R.string.photos_deleted), Toast.LENGTH_SHORT).show();
                            photoUris.removeAll(deleteUris);
                            deleteUris.clear();
                            actionStack.clear();
                            btnUndo.setEnabled(false);
                            updateDeleteButtonState();
                            if (currentIndex > photoUris.size()) currentIndex = photoUris.size();
                            if (currentIndex == photoUris.size() && currentIndex > 0) currentIndex--;
                            showCurrentPhoto();
                        } else {
                            Toast.makeText(this, getString(R.string.delete_canceled), Toast.LENGTH_SHORT).show();
                        }
                    }
            );

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        Button btnPickPhotos = findViewById(R.id.btnPickPhotos);
        Button btnScanAll = findViewById(R.id.btnScanAll);
        btnUndo = findViewById(R.id.btnUndo);
        imageViewPhoto = findViewById(R.id.imageViewPhoto);
        sideIndicatorLeft = findViewById(R.id.sideIndicatorLeft);
        sideIndicatorRight = findViewById(R.id.sideIndicatorRight);
        tvProgress = findViewById(R.id.tvProgress);
        progressBar = findViewById(R.id.progressBar);
        btnDeleteMarked = findViewById(R.id.btnDeleteMarked);

        btnPickPhotos.setOnClickListener(v ->
                pickMedia.launch(
                        new PickVisualMediaRequest.Builder()
                                .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                                .build()
                )
        );

        btnScanAll.setOnClickListener(v -> checkPermissionsAndScan());

        btnUndo.setOnClickListener(v -> undoLastAction());
        btnDeleteMarked.setOnClickListener(v -> deleteMarkedPhotos());

        imageViewPhoto.setOnTouchListener((v, event) -> {
            if (photoUris.isEmpty() || currentIndex >= photoUris.size()) return false;

            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    downX = event.getRawX();
                    return true;

                case MotionEvent.ACTION_MOVE:
                    float deltaX = event.getRawX() - downX;
                    v.setTranslationX(deltaX);
                    v.setRotation(deltaX * 0.05f);
                    updateIndicators(deltaX);
                    return true;

                case MotionEvent.ACTION_UP:
                    float finalDeltaX = event.getRawX() - downX;
                    if (Math.abs(finalDeltaX) > SWIPE_THRESHOLD) {
                        animateAndHandleSwipe(finalDeltaX < 0);
                    } else {
                        if (Math.abs(finalDeltaX) < 10) v.performClick();
                        resetPhotoPosition();
                    }
                    return true;
            }
            return false;
        });

        updateProgress();
        updateDeleteButtonState();
        checkAndShowInstructions();
    }

    private void checkPermissionsAndScan() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED) {
                scanAllPhotos();
            } else {
                requestPermissionLauncher.launch(new String[]{Manifest.permission.READ_MEDIA_IMAGES});
            }
        } else {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                scanAllPhotos();
            } else {
                requestPermissionLauncher.launch(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE});
            }
        }
    }

    private void scanAllPhotos() {
        Toast.makeText(this, getString(R.string.scanning_photos), Toast.LENGTH_SHORT).show();
        ArrayList<Uri> allPhotos = new ArrayList<>();
        Uri collection;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL);
        } else {
            collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        }

        String[] projection = new String[]{MediaStore.Images.Media._ID};
        String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";

        try (Cursor cursor = getContentResolver().query(collection, projection, null, null, sortOrder)) {
            if (cursor != null) {
                int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
                while (cursor.moveToNext()) {
                    long id = cursor.getLong(idColumn);
                    Uri contentUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);
                    allPhotos.add(contentUri);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error scanning photos", e);
        }

        if (allPhotos.isEmpty()) {
            Toast.makeText(this, getString(R.string.no_photos_selected), Toast.LENGTH_SHORT).show();
        } else {
            setupPhotoList(allPhotos);
        }
    }

    private void setupPhotoList(List<Uri> uris) {
        photoUris.clear();
        photoUris.addAll(uris);
        deleteUris.clear();
        keepUris.clear();
        actionStack.clear();
        currentIndex = 0;
        btnUndo.setEnabled(false);
        updateDeleteButtonState();
        showCurrentPhoto();
    }

    private void checkAndShowInstructions() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        boolean showInstructions = prefs.getBoolean(PREF_SHOW_INSTRUCTIONS, true);

        if (showInstructions) {
            View dialogView = getLayoutInflater().inflate(R.layout.dialog_instructions, null);
            CheckBox checkBox = dialogView.findViewById(R.id.checkBoxDontShow);

            new MaterialAlertDialogBuilder(this)
                    .setTitle(R.string.how_to_use)
                    .setView(dialogView)
                    .setPositiveButton(R.string.ok, (dialog, which) -> {
                        if (checkBox.isChecked()) {
                            prefs.edit().putBoolean(PREF_SHOW_INSTRUCTIONS, false).apply();
                        }
                    })
                    .show();
        }
    }

    private void updateIndicators(float deltaX) {
        float alpha = Math.min(Math.abs(deltaX) / SWIPE_THRESHOLD, 1.0f);
        if (deltaX < 0) { // Swiping left (Delete)
            sideIndicatorLeft.setVisibility(View.VISIBLE);
            sideIndicatorLeft.setAlpha(alpha);
            sideIndicatorRight.setVisibility(View.GONE);
        } else if (deltaX > 0) { // Swiping right (Keep)
            sideIndicatorRight.setVisibility(View.VISIBLE);
            sideIndicatorRight.setAlpha(alpha);
            sideIndicatorLeft.setVisibility(View.GONE);
        } else {
            sideIndicatorLeft.setVisibility(View.GONE);
            sideIndicatorRight.setVisibility(View.GONE);
        }
    }

    private void resetPhotoPosition() {
        imageViewPhoto.animate()
                .translationX(0)
                .rotation(0)
                .setDuration(200)
                .withEndAction(() -> {
                    sideIndicatorLeft.setVisibility(View.GONE);
                    sideIndicatorRight.setVisibility(View.GONE);
                })
                .start();
    }

    private void animateAndHandleSwipe(boolean markForDelete) {
        float endX = markForDelete ? -imageViewPhoto.getWidth() * 1.5f : imageViewPhoto.getWidth() * 1.5f;
        imageViewPhoto.animate()
                .translationX(endX)
                .alpha(0)
                .setDuration(300)
                .withEndAction(() -> {
                    handleSwipe(markForDelete);
                    imageViewPhoto.setTranslationX(0);
                    imageViewPhoto.setRotation(0);
                    imageViewPhoto.setAlpha(1.0f);
                    sideIndicatorLeft.setVisibility(View.GONE);
                    sideIndicatorRight.setVisibility(View.GONE);
                })
                .start();
    }

    private void handleSwipe(boolean markForDelete) {
        if (photoUris.isEmpty() || currentIndex >= photoUris.size()) return;

        Uri currentUri = photoUris.get(currentIndex);
        if (markForDelete) {
            deleteUris.add(currentUri);
            Toast.makeText(this, getString(R.string.marked_for_delete), Toast.LENGTH_SHORT).show();
        } else {
            keepUris.add(currentUri);
            Toast.makeText(this, getString(R.string.kept), Toast.LENGTH_SHORT).show();
        }

        actionStack.add(new SwipeAction(currentUri, markForDelete));
        currentIndex++;
        btnUndo.setEnabled(true);
        updateDeleteButtonState();

        if (currentIndex >= photoUris.size()) {
            imageViewPhoto.setImageDrawable(null);
            updateProgress();
            Toast.makeText(this, getString(R.string.done_message, keepUris.size(), deleteUris.size()), Toast.LENGTH_LONG).show();
            return;
        }
        showCurrentPhoto();
    }

    private void undoLastAction() {
        if (actionStack.isEmpty()) return;
        SwipeAction lastAction = actionStack.remove(actionStack.size() - 1);
        if (lastAction.markedForDelete) {
            if (!deleteUris.isEmpty()) deleteUris.remove(deleteUris.size() - 1);
        } else {
            if (!keepUris.isEmpty()) keepUris.remove(keepUris.size() - 1);
        }
        currentIndex--;
        if (currentIndex < 0) currentIndex = 0;
        btnUndo.setEnabled(!actionStack.isEmpty());
        updateDeleteButtonState();
        showCurrentPhoto();
        Toast.makeText(this, getString(R.string.undid_last_action), Toast.LENGTH_SHORT).show();
    }

    private void showCurrentPhoto() {
        if (photoUris.isEmpty() || currentIndex >= photoUris.size()) {
            imageViewPhoto.setImageDrawable(null);
            updateProgress();
            return;
        }
        imageViewPhoto.setImageURI(photoUris.get(currentIndex));
        updateProgress();
    }

    private void updateProgress() {
        int total = photoUris.size();
        int reviewed = Math.min(currentIndex, total);
        if (total == 0) {
            tvProgress.setText(getString(R.string.progress_text));
            progressBar.setMax(1);
            progressBar.setProgress(0);
            return;
        }
        tvProgress.setText(getString(R.string.progress_format, reviewed, total));
        progressBar.setMax(total);
        progressBar.setProgress(reviewed);
    }

    private void updateDeleteButtonState() {
        btnDeleteMarked.setEnabled(!deleteUris.isEmpty());
    }

    private static class SwipeAction {
        Uri uri;
        boolean markedForDelete;
        SwipeAction(Uri uri, boolean markedForDelete) {
            this.uri = uri;
            this.markedForDelete = markedForDelete;
        }
    }

    private void deleteMarkedPhotos() {
        if (deleteUris.isEmpty()) {
            Toast.makeText(this, getString(R.string.no_photos_marked), Toast.LENGTH_SHORT).show();
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                List<Uri> mediaStoreUris = new ArrayList<>();
                for (Uri uri : deleteUris) {
                    Uri resolvedUri = resolveToMediaStoreUri(uri);
                    if (resolvedUri != null) mediaStoreUris.add(resolvedUri);
                }
                if (mediaStoreUris.isEmpty()) {
                    Toast.makeText(this, "Could not resolve photos for deletion", Toast.LENGTH_SHORT).show();
                    return;
                }
                PendingIntent pendingIntent = MediaStore.createDeleteRequest(getContentResolver(), mediaStoreUris);
                IntentSenderRequest request = new IntentSenderRequest.Builder(pendingIntent.getIntentSender()).build();
                deleteLauncher.launch(request);
            } catch (Exception e) {
                Toast.makeText(this, getString(R.string.delete_request_error), Toast.LENGTH_SHORT).show();
                Log.e(TAG, "Error creating delete request", e);
            }
        } else {
            Toast.makeText(this, getString(R.string.api_too_low), Toast.LENGTH_LONG).show();
        }
    }

    private Uri resolveToMediaStoreUri(Uri pickerUri) {
        String uriString = pickerUri.toString();
        if (uriString.contains("com.android.providers.media.photopicker")) {
            String id = pickerUri.getLastPathSegment();
            if (id != null) {
                return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, Long.parseLong(id));
            }
        }
        if (uriString.startsWith("content://media/external/images/media/")) return pickerUri;
        return null;
    }
}
