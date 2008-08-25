This plugin checks for crash logs on application startup and posts them to a URL declared in `[NSBundle mainBundle]`'s Info.plist. Use the `BCrashReporterPostToURL` key specify that URL:

    <key>BCrashReporterPostToURL</key>
    <string>http://yourcompany.com/report_crash</string>
