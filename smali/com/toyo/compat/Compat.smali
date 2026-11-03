.class public final Lcom/toyo/compat/Compat;
.super Ljava/lang/Object;


.method public static buildNotification(Landroid/content/Context;Ljava/lang/String;)Landroid/app/Notification;
    .locals 6

    invoke-virtual {p0}, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;
    move-result-object v0

    new-instance v1, Landroid/content/Intent;
    const-class v2, Lcom/toyo/music/player/MusicPlayerActivity;
    invoke-direct {v1, v0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    const/high16 v2, 0x20000000
    invoke-virtual {v1, v2}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;

    const/4 v2, 0x0
    const/high16 v3, 0xc000000
    invoke-static {v0, v2, v1, v3}, Landroid/app/PendingIntent;->getActivity(Landroid/content/Context;ILandroid/content/Intent;I)Landroid/app/PendingIntent;
    move-result-object v1

    sget v2, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v3, 0x1a
    if-lt v2, v3, :old

    const-string v2, "notification"
    invoke-virtual {v0, v2}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v2
    check-cast v2, Landroid/app/NotificationManager;
    new-instance v3, Landroid/app/NotificationChannel;
    const-string v4, "playback"
    const-string v5, "Music playback"
    const/4 v0, 0x2
    invoke-direct {v3, v4, v5, v0}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V
    invoke-virtual {v2, v3}, Landroid/app/NotificationManager;->createNotificationChannel(Landroid/app/NotificationChannel;)V
    new-instance v2, Landroid/app/Notification$Builder;
    invoke-direct {v2, p0, v4}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;Ljava/lang/String;)V
    goto :build

    :old
    new-instance v2, Landroid/app/Notification$Builder;
    invoke-direct {v2, p0}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;)V

    :build
    const v3, 0x7f020007
    invoke-virtual {v2, v3}, Landroid/app/Notification$Builder;->setSmallIcon(I)Landroid/app/Notification$Builder;
    const-string v3, "Holiday Brilliant"
    invoke-virtual {v2, v3}, Landroid/app/Notification$Builder;->setContentTitle(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;
    if-nez p1, :hastext
    const-string p1, ""
    :hastext
    invoke-virtual {v2, p1}, Landroid/app/Notification$Builder;->setContentText(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;
    invoke-virtual {v2, v1}, Landroid/app/Notification$Builder;->setContentIntent(Landroid/app/PendingIntent;)Landroid/app/Notification$Builder;
    const/4 v3, 0x1
    invoke-virtual {v2, v3}, Landroid/app/Notification$Builder;->setOngoing(Z)Landroid/app/Notification$Builder;
    invoke-virtual {v2}, Landroid/app/Notification$Builder;->build()Landroid/app/Notification;
    move-result-object v0
    return-object v0
.end method


.method public static startForeground(Landroid/app/Service;ILandroid/app/Notification;)V
    .locals 2

    :try_start_0
    invoke-virtual {p0, p1, p2}, Landroid/app/Service;->startForeground(ILandroid/app/Notification;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    return-void

    :catch_0
    move-exception v0
    :try_start_1
    const-string v0, "notification"
    invoke-virtual {p0, v0}, Landroid/app/Service;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Landroid/app/NotificationManager;
    invoke-virtual {v0, p1, p2}, Landroid/app/NotificationManager;->notify(ILandroid/app/Notification;)V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1
    :catch_1
    return-void
.end method


.method public static query(Landroid/content/ContentResolver;Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .locals 1

    :try_start_0
    invoke-virtual/range {p0 .. p5}, Landroid/content/ContentResolver;->query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    return-object v0

    :catch_0
    move-exception v0
    const/4 v0, 0x0
    return-object v0
.end method


.method private static addIfMissing(Landroid/app/Activity;Ljava/util/ArrayList;Ljava/lang/String;)V
    .locals 1

    invoke-virtual {p0, p2}, Landroid/app/Activity;->checkSelfPermission(Ljava/lang/String;)I
    move-result v0
    if-eqz v0, :granted
    invoke-virtual {p1, p2}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    :granted
    return-void
.end method


# Returns true if a permission dialog was shown (caller then waits for onRequestPermissionsResult).
.method public static requestStartupPermissions(Landroid/app/Activity;)Z
    .locals 4

    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v1, 0x17
    if-lt v0, v1, :no

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V

    const/16 v1, 0x21
    if-lt v0, v1, :pre33
    const-string v3, "android.permission.READ_MEDIA_AUDIO"
    invoke-static {p0, v2, v3}, Lcom/toyo/compat/Compat;->addIfMissing(Landroid/app/Activity;Ljava/util/ArrayList;Ljava/lang/String;)V
    const-string v3, "android.permission.POST_NOTIFICATIONS"
    invoke-static {p0, v2, v3}, Lcom/toyo/compat/Compat;->addIfMissing(Landroid/app/Activity;Ljava/util/ArrayList;Ljava/lang/String;)V
    goto :bt

    :pre33
    const-string v3, "android.permission.READ_EXTERNAL_STORAGE"
    invoke-static {p0, v2, v3}, Lcom/toyo/compat/Compat;->addIfMissing(Landroid/app/Activity;Ljava/util/ArrayList;Ljava/lang/String;)V

    :bt
    const/16 v1, 0x1f
    if-lt v0, v1, :ask
    const-string v3, "android.permission.BLUETOOTH_CONNECT"
    invoke-static {p0, v2, v3}, Lcom/toyo/compat/Compat;->addIfMissing(Landroid/app/Activity;Ljava/util/ArrayList;Ljava/lang/String;)V

    :ask
    invoke-virtual {v2}, Ljava/util/ArrayList;->size()I
    move-result v0
    if-eqz v0, :no

    new-array v0, v0, [Ljava/lang/String;
    invoke-virtual {v2, v0}, Ljava/util/ArrayList;->toArray([Ljava/lang/Object;)[Ljava/lang/Object;
    move-result-object v0
    check-cast v0, [Ljava/lang/String;
    const/4 v1, 0x1
    invoke-virtual {p0, v0, v1}, Landroid/app/Activity;->requestPermissions([Ljava/lang/String;I)V
    const/4 v0, 0x1
    return v0

    :no
    const/4 v0, 0x0
    return v0
.end method
