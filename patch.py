#!/usr/bin/env python3
"""Patch a decompiled (apktool) Holiday Brilliant 1.3 tree for modern Android.
Usage: patch.py <apktool-output-dir>
Every replacement asserts it matched, so it fails loudly on a different APK version."""
import re, sys, os, shutil
if len(sys.argv) != 2: sys.exit(__doc__)
R = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
def rw(p, fn):
    p = os.path.join(R, p); s = open(p).read(); t = fn(s)
    assert t != s, p
    open(p, 'w').write(t)
def sub1(s, a, b, n=1):
    assert s.count(a) == n, (a[:80], s.count(a)); return s.replace(a, b)

# Add the helper class (notifications, permissions, safe media query)
os.makedirs(os.path.join(R, 'smali/com/toyo/compat'), exist_ok=True)
shutil.copy(os.path.join(HERE, 'smali/com/toyo/compat/Compat.smali'), os.path.join(R, 'smali/com/toyo/compat/Compat.smali'))

MS = 'smali/com/toyo/music/player/MusicService.smali'
def ms(s):
    # replace a(String) and b(String) bodies
    a_new = '''.method a(Ljava/lang/String;)V
    .locals 3

    invoke-static {p0, p1}, Lcom/toyo/compat/Compat;->buildNotification(Landroid/content/Context;Ljava/lang/String;)Landroid/app/Notification;

    move-result-object v0

    iput-object v0, p0, Lcom/toyo/music/player/MusicService;->k:Landroid/app/Notification;

    const/4 v1, 0x1

    invoke-static {p0, v1, v0}, Lcom/toyo/compat/Compat;->startForeground(Landroid/app/Service;ILandroid/app/Notification;)V

    return-void
.end method'''
    b_new = a_new.replace('.method a(', '.method b(')
    s, n = re.subn(r'\.method a\(Ljava/lang/String;\)V.*?\.end method', a_new, s, flags=re.S); assert n == 1
    s, n = re.subn(r'\.method b\(Ljava/lang/String;\)V.*?\.end method', b_new, s, flags=re.S); assert n == 1
    # b(Z): only drop foreground on pause (z=false), not during track changes (Android 12+ forbids re-entering foreground from background)
    s = sub1(s, '''    const/4 v0, 0x1

    invoke-virtual {p0, v0}, Lcom/toyo/music/player/MusicService;->stopForeground(Z)V

    if-eqz p1, :cond_0
''', '''    if-nez p1, :keepfg

    const/4 v0, 0x1

    invoke-virtual {p0, v0}, Lcom/toyo/music/player/MusicService;->stopForeground(Z)V

    :keepfg
    if-eqz p1, :cond_0
''')
    # h/i/j: end of playlist -> remove notification
    s = sub1(s, '''    if-nez v0, :cond_0

    :goto_0
    return-void''', '''    if-nez v0, :cond_0

    const/4 v1, 0x1

    invoke-virtual {p0, v1}, Lcom/toyo/music/player/MusicService;->stopForeground(Z)V

    :goto_0
    return-void''', 3)
    # catch any exception when opening a song, not only IOException
    s = sub1(s, '.catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0', '.catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0', 3)
    s = sub1(s, 'Ljava/io/IOException;->getMessage()', 'Ljava/lang/Exception;->getMessage()', 3)
    s = sub1(s, '''    invoke-virtual {v0}, Ljava/io/IOException;->printStackTrace()V

    goto :goto_0''', '''    invoke-virtual {v0}, Ljava/lang/Exception;->printStackTrace()V

    const/4 v1, 0x1

    invoke-virtual {p0, v1}, Lcom/toyo/music/player/MusicService;->stopForeground(Z)V

    goto :goto_0''', 3)
    # onError: drop foreground
    s = sub1(s, '''    invoke-virtual {p0, v3}, Lcom/toyo/music/player/MusicService;->b(Z)V

    invoke-virtual {p0}, Lcom/toyo/music/player/MusicService;->e()V

    return v3''', '''    invoke-virtual {p0, v3}, Lcom/toyo/music/player/MusicService;->b(Z)V

    invoke-virtual {p0, v3}, Lcom/toyo/music/player/MusicService;->stopForeground(Z)V

    invoke-virtual {p0}, Lcom/toyo/music/player/MusicService;->e()V

    return v3''')
    return s
rw(MS, ms)

MP = 'smali/com/toyo/music/player/MusicPlayerActivity.smali'
def mp(s):
    s = sub1(s, '.catch Ljava/io/FileNotFoundException; {:try_start_0 .. :try_end_0} :catch_0', '.catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0')
    s = sub1(s, 'invoke-virtual/range {v0 .. v5}, Landroid/content/ContentResolver;->query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;',
                'invoke-static/range {v0 .. v5}, Lcom/toyo/compat/Compat;->query(Landroid/content/ContentResolver;Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;')
    return s
rw(MP, mp)

SP = 'smali/com/toyo/SplashActivity.smali'
def sp(s):
    s = sub1(s, '''    invoke-virtual {p0, v0}, Lcom/toyo/SplashActivity;->setContentView(I)V
''', '''    invoke-virtual {p0, v0}, Lcom/toyo/SplashActivity;->setContentView(I)V

    invoke-static {p0}, Lcom/toyo/compat/Compat;->requestStartupPermissions(Landroid/app/Activity;)Z

    move-result v0

    if-eqz v0, :go

    return-void

    :go
''')
    s += '''

.method public onRequestPermissionsResult(I[Ljava/lang/String;[I)V
    .locals 4

    new-instance v0, Landroid/os/Handler;

    invoke-direct {v0}, Landroid/os/Handler;-><init>()V

    new-instance v1, Lcom/toyo/q;

    invoke-direct {v1, p0}, Lcom/toyo/q;-><init>(Lcom/toyo/SplashActivity;)V

    const-wide/16 v2, 0xc8

    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void
.end method
'''
    return s
rw(SP, sp)

# Manifest
MF = 'AndroidManifest.xml'
def mf(s):
    s = re.sub(r' platformBuildVersion\w+="[^"]*"', '', s)
    s = sub1(s, '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>', '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>\n    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>')
    s = sub1(s, '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>', '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="18"/>')
    s = sub1(s, '<uses-permission android:name="android.permission.BLUETOOTH"/>', '<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>\n    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>')
    s = sub1(s, '    <uses-permission android:name="com.android.vending.CHECK_LICENSE"/>\n', '')
    s = sub1(s, '<activity android:name="com.toyo.SplashActivity"/>', '''<activity android:exported="true" android:name="com.toyo.SplashActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>''')
    s = sub1(s, '<activity android:name="com.toyo.MainActivity"/>', '<activity android:exported="false" android:name="com.toyo.MainActivity"/>')
    s = sub1(s, '<activity android:configChanges="orientation" android:name="com.toyo.music.player.MusicPlayerActivity"', '<activity android:configChanges="orientation|screenSize" android:exported="false" android:name="com.toyo.music.player.MusicPlayerActivity"')
    s = sub1(s, '<service android:exported="true" android:name="com.toyo.music.player.MusicService"/>', '<service android:exported="false" android:foregroundServiceType="mediaPlayback" android:name="com.toyo.music.player.MusicService"/>')
    s = sub1(s, '<receiver android:name="com.toyo.music.player.MusicIntentReceiver">', '<receiver android:exported="false" android:name="com.toyo.music.player.MusicIntentReceiver">')
    s, n = re.subn(r'\s*<activity android:label="@string/app_name" android:name="com.toyo.holidaybrilliant.LicenseCheckActivity">.*?</activity>', '', s, flags=re.S); assert n == 1
    return s
rw(MF, mf)

Y = 'apktool.yml'
# Version can be overridden (the release workflow does this so every release upgrades the previous one)
VC = os.environ.get('VERSION_CODE', '6'); VN = os.environ.get('VERSION_NAME', '1.3-offline')
assert VC.isdigit() and int(VC) > 5, 'VERSION_CODE must be an integer above 5'
rw(Y, lambda s: sub1(sub1(sub1(s, "targetSdkVersion: 19", "targetSdkVersion: 34"), "versionCode: 5", "versionCode: " + VC), "versionName: 1.3", "versionName: '" + VN + "'"))
print("patched")
