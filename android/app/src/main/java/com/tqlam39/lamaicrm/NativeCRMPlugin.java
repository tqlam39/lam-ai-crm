package com.tqlam39.lamaicrm;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.net.Uri;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.speech.RecognizerIntent;
import android.text.Html;
import android.util.Base64;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;

@CapacitorPlugin(name = "NativeCRM")
public class NativeCRMPlugin extends Plugin {
    private static final int MAX_DB = 100 * 1024 * 1024;
    private final ExecutorService disk = Executors.newSingleThreadExecutor();
    private final ExecutorService network = Executors.newFixedThreadPool(2);
    private SQLiteOpenHelper helper;
    private boolean documentOpen = false;
    @Override public void load() {
        helper = new SQLiteOpenHelper(getContext(), "lam-crm.db", null, 1) {
            @Override public void onCreate(SQLiteDatabase db) {
                db.execSQL("CREATE TABLE snapshot_chunks (position INTEGER PRIMARY KEY, content TEXT NOT NULL)");
            }
            @Override public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
                throw new IllegalStateException("Unsupported database migration");
            }
        };
        helper.setWriteAheadLoggingEnabled(true);
    }
    @PluginMethod public void readDatabase(PluginCall call) {
        disk.execute(() -> {
            try {
                StringBuilder text = new StringBuilder();
                try (Cursor rows = helper.getReadableDatabase().rawQuery("SELECT content FROM snapshot_chunks ORDER BY position", null)) {
                    while (rows.moveToNext()) { text.append(rows.getString(0)); if (text.length() > MAX_DB) throw new IOException(); }
                }
                JSObject out = new JSObject(); out.put("text", text.toString()); call.resolve(out);
            } catch (Exception e) { call.reject("Không đọc được SQLite. Dữ liệu chưa bị thay đổi."); }
        });
    }
    @PluginMethod public void writeDatabase(PluginCall call) {
        final String text = call.getString("text", "");
        disk.execute(() -> {
            try {
                if (text.length() > MAX_DB) throw new IOException();
                JSONObject data = new JSONObject(text);
                for (String field : new String[]{"properties","customers","requirements","tasks","activities","drafts"}) data.getJSONArray(field);
                data.getJSONObject("settings");
                SQLiteDatabase db = helper.getWritableDatabase();
                db.beginTransaction();
                try {
                    db.delete("snapshot_chunks", null, null);
                    int index = 0;
                    for (int start = 0; start < text.length();) {
                        int end = Math.min(start + 128 * 1024, text.length());
                        if (end < text.length() && Character.isHighSurrogate(text.charAt(end - 1))) end--;
                        ContentValues row = new ContentValues(); row.put("position", index++); row.put("content", text.substring(start, end));
                        db.insertOrThrow("snapshot_chunks", null, row); start = end;
                    }
                    db.setTransactionSuccessful();
                } finally { db.endTransaction(); }
                call.resolve();
            } catch (Exception e) { call.reject("Không lưu được SQLite. Kiểm tra dung lượng điện thoại (database tối đa 100 MB)."); }
        });
    }
    @PluginMethod public void exportDocument(PluginCall call) {
        if (documentOpen) { call.reject("Đang chọn tệp khác"); return; }
        String text = call.getString("text", "");
        if (text.length() > MAX_DB) { call.reject("Bản sao lưu vượt 100 MB"); return; }
        documentOpen = true;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT); intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(call.getString("mime", "application/json")); intent.putExtra(Intent.EXTRA_TITLE, call.getString("name", "LAM-CRM.json"));
        try { startActivityForResult(call, intent, "exportResult"); }
        catch (Exception e) { documentOpen = false; call.reject("Không mở được trình chọn tệp Android"); }
    }
    @ActivityCallback private void exportResult(PluginCall call, ActivityResult result) {
        documentOpen = false; if (call == null) return;
        if (result.getResultCode() != Activity.RESULT_OK || result.getData() == null || result.getData().getData() == null) { call.reject("Đã hủy sao lưu"); return; }
        Uri uri = result.getData().getData();
        disk.execute(() -> {
            try (OutputStream output = getContext().getContentResolver().openOutputStream(uri, "wt")) {
                if (output == null) throw new IOException();
                output.write(call.getString("text", "").getBytes(StandardCharsets.UTF_8)); output.flush();
                call.resolve();
            } catch (Exception e) { call.reject("Chưa ghi được bản sao lưu. Kiểm tra Drive/mạng/dung lượng; không dùng tệp chưa hoàn tất để khôi phục."); }
        });
    }
    @PluginMethod public void importDocument(PluginCall call) {
        if (documentOpen) { call.reject("Đang chọn tệp khác"); return; }
        documentOpen = true;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT); intent.addCategory(Intent.CATEGORY_OPENABLE); intent.setType("*/*");
        try { startActivityForResult(call, intent, "importResult"); }
        catch (Exception e) { documentOpen = false; call.reject("Không mở được trình chọn tệp Android"); }
    }
    @ActivityCallback private void importResult(PluginCall call, ActivityResult result) {
        documentOpen = false; if (call == null) return;
        if (result.getResultCode() != Activity.RESULT_OK || result.getData() == null || result.getData().getData() == null) { call.reject("Đã hủy chọn bản sao lưu"); return; }
        Uri uri = result.getData().getData();
        disk.execute(() -> {
            try (InputStream input = getContext().getContentResolver().openInputStream(uri)) {
                JSObject out = new JSObject(); out.put("text", readBounded(input, MAX_DB)); call.resolve(out);
            } catch (Exception e) { call.reject("Không đọc được tệp hoặc tệp vượt 100 MB"); }
        });
    }
    @PluginMethod public void recognizeSpeech(PluginCall call) {
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "vi-VN"); intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Đọc thông tin BĐS / nhu cầu khách");
        try { startActivityForResult(call, intent, "speechResult"); }
        catch (Exception e) { call.reject("Điện thoại chưa có dịch vụ nhận giọng nói. Dùng micro trên bàn phím."); }
    }
    @ActivityCallback private void speechResult(PluginCall call, ActivityResult result) {
        if (call == null) return;
        if (result.getResultCode() != Activity.RESULT_OK || result.getData() == null) { call.reject("Đã hủy nhận giọng nói"); return; }
        ArrayList<String> texts = result.getData().getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
        JSObject out = new JSObject(); out.put("text", texts == null || texts.isEmpty() ? "" : texts.get(0)); call.resolve(out);
    }
    private SharedPreferences prefs() { return getContext().getSharedPreferences("ai-private", 0); }
    private boolean validProvider(String p) { return p.equals("openai") || p.equals("groq") || p.equals("gemini"); }
    private synchronized SecretKey encryptionKey() throws Exception {
        KeyStore ks = KeyStore.getInstance("AndroidKeyStore"); ks.load(null);
        if (!ks.containsAlias("lam-crm-ai")) {
            KeyGenerator gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            gen.init(new KeyGenParameterSpec.Builder("lam-crm-ai", KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build()); gen.generateKey();
        }
        return (SecretKey) ks.getKey("lam-crm-ai", null);
    }
    private String encrypt(String text) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding"); cipher.init(Cipher.ENCRYPT_MODE, encryptionKey());
        return Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP) + ":" + Base64.encodeToString(cipher.doFinal(text.getBytes(StandardCharsets.UTF_8)), Base64.NO_WRAP);
    }
    private String decrypt(String data) throws Exception {
        if (data.isEmpty()) return "";
        String[] parts = data.split(":", 2); Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, encryptionKey(), new GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)));
        return new String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), StandardCharsets.UTF_8);
    }
    private JSObject config() {
        JSObject out = new JSObject(), providers = new JSObject();
        for (String p : new String[]{"openai","groq","gemini"}) {
            JSObject row = new JSObject(); row.put("configured", !prefs().getString(p + "-key", "").isEmpty());
            row.put("model", prefs().getString(p + "-model", "")); providers.put(p, row);
        }
        out.put("active", prefs().getString("active", "groq")); out.put("providers", providers); return out;
    }
    @PluginMethod public void getAIConfig(PluginCall call) { call.resolve(config()); }
    @PluginMethod public void setAIConfig(PluginCall call) {
        disk.execute(() -> {
            try {
                String p = call.getString("provider", ""); if (!validProvider(p)) throw new Exception();
                SharedPreferences.Editor edit = prefs().edit();
                if (call.getBoolean("remove", false)) { edit.remove(p + "-key"); edit.remove(p + "-model"); }
                else {
                    String key = call.getString("key", "");
                    if (!key.isEmpty()) edit.putString(p + "-key", encrypt(key));
                    edit.putString(p + "-model", call.getString("model", "")); edit.putString("active", p);
                }
                if (!edit.commit()) throw new IOException(); call.resolve(config());
            } catch (Exception e) { call.reject("Không lưu được key an toàn trên thiết bị"); }
        });
    }
    @PluginMethod public void aiRequest(PluginCall call) {
        network.execute(() -> {
            HttpURLConnection connection = null;
            try {
                String p = call.getString("provider", ""); if (!validProvider(p)) throw new Exception();
                String key = call.getString("key", ""); if (key.isEmpty()) key = decrypt(prefs().getString(p + "-key", ""));
                if (key.isEmpty()) { call.reject("Nhập API key trong Cài đặt"); return; }
                String model = call.getString("model", ""); boolean models = call.getString("operation", "generate").equals("models");
                if (models && !p.equals("groq")) throw new Exception();
                if (!models && !model.matches("[A-Za-z0-9._:/-]{1,150}")) { call.reject("Tên model không hợp lệ"); return; }
                String endpoint = models ? "https://api.groq.com/openai/v1/models" : p.equals("groq") ? "https://api.groq.com/openai/v1/chat/completions" : p.equals("openai") ? "https://api.openai.com/v1/chat/completions" : "https://generativelanguage.googleapis.com/v1beta/models/" + URLEncoder.encode(model, "UTF-8") + ":generateContent";
                connection = (HttpURLConnection) new URL(endpoint).openConnection(); connection.setInstanceFollowRedirects(false);
                connection.setConnectTimeout(15000); connection.setReadTimeout(45000);
                connection.setRequestProperty(p.equals("gemini") ? "x-goog-api-key" : "Authorization", p.equals("gemini") ? key : "Bearer " + key);
                if (!models) {
                    byte[] payload = call.getString("payload", "{}").getBytes(StandardCharsets.UTF_8); if (payload.length > 12 * 1024 * 1024) throw new IOException();
                    connection.setRequestMethod("POST"); connection.setRequestProperty("Content-Type", "application/json"); connection.setDoOutput(true);
                    try (OutputStream output = connection.getOutputStream()) { output.write(payload); }
                }
                int status = connection.getResponseCode(); JSObject out = new JSObject(); out.put("status", status);
                // Provider errors are not echoed to avoid accidentally exposing key/payload details.
                out.put("text", status >= 200 && status < 300 ? readBounded(connection.getInputStream(), 8 * 1024 * 1024) : "{}"); call.resolve(out);
            } catch (Exception e) { call.reject("Không kết nối được AI. Kiểm tra mạng, key và model."); }
            finally { if (connection != null) connection.disconnect(); }
        });
    }
    private URL publicUrl(String text) throws Exception {
        URL url = new URL(text);
        if (!url.getProtocol().equals("https") || url.getUserInfo() != null || (url.getPort() != -1 && url.getPort() != 443)) throw new IOException();
        for (InetAddress ip : InetAddress.getAllByName(url.getHost())) {
            if (ip.isAnyLocalAddress() || ip.isLoopbackAddress() || ip.isLinkLocalAddress() || ip.isSiteLocalAddress() || ip.isMulticastAddress()) throw new IOException();
            byte[] b = ip.getAddress(); if (b.length == 16 && (b[0] & 0xfe) == 0xfc) throw new IOException();
        }
        return url;
    }
    @PluginMethod public void readPublicLink(PluginCall call) {
        network.execute(() -> {
            HttpURLConnection c = null;
            try {
                URL url = publicUrl(call.getString("url", ""));
                for (int redirects = 0; redirects < 5; redirects++) {
                    c = (HttpURLConnection) url.openConnection(); c.setInstanceFollowRedirects(false); c.setConnectTimeout(12000); c.setReadTimeout(15000);
                    c.setRequestProperty("Accept", "text/html,text/plain"); c.setRequestProperty("User-Agent", "LAM-CRM-Android/1.0");
                    int code = c.getResponseCode();
                    if (code >= 300 && code < 400) { String target = c.getHeaderField("Location"); c.disconnect(); url = publicUrl(new URL(url, target).toString()); continue; }
                    if (code != 200 || c.getContentType() == null || !(c.getContentType().contains("text/html") || c.getContentType().contains("text/plain"))) throw new IOException();
                    String raw = readBounded(c.getInputStream(), 2 * 1024 * 1024);
                    raw = raw.replaceAll("(?is)<(script|style|noscript|nav|footer|header)[^>]*>.*?</\\1>", " ").replaceAll("(?is)<!--.*?-->", " ");
                    String text = Html.fromHtml(raw, Html.FROM_HTML_MODE_LEGACY).toString().trim();
                    if (text.length() < 60 || (url.getHost().contains("facebook.com") && (url.getPath().contains("login") || url.getPath().contains("checkpoint")))) throw new IOException();
                    JSObject out = new JSObject(); out.put("text", text.substring(0, Math.min(text.length(), 30000))); out.put("title", url.getHost()); out.put("url", url.toString()); out.put("truncated", text.length() > 30000); call.resolve(out); return;
                }
                throw new IOException();
            } catch (Exception e) { call.reject("Không đọc được link HTTPS công khai. Trang có thể chặn hoặc yêu cầu đăng nhập; hãy dán nội dung hoặc dùng ảnh chụp."); }
            finally { if (c != null) c.disconnect(); }
        });
    }
    private String readBounded(InputStream input, int max) throws IOException {
        if (input == null) throw new IOException();
        try (InputStream source = input; ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            byte[] chunk = new byte[8192]; int size;
            while ((size = source.read(chunk)) != -1) { if (bytes.size() + size > max) throw new IOException(); bytes.write(chunk, 0, size); }
            return bytes.toString(StandardCharsets.UTF_8.name());
        }
    }
}
