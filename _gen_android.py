import json, os

with open('twa-manifest.json') as f:
    m = json.load(f)

pkg = m['packageId']
host = m['host'].replace('https://', '').replace('http://', '')

# Read template, fill values
with open('app/build.gradle.template') as f:
    template = f.read()

# Simple placeholder substitution
template = template.replace('<%= packageId %>', pkg)
template = template.replace('<%= host %>', host)
template = template.replace('<%= startUrl %>', m.get('startUrl', '/'))
template = template.replace('<%= escapeGradleString(name) %>', m['name'])
template = template.replace('<%= escapeGradleString(launcherName) %>', m['launcherName'])
template = template.replace('<%= themeColor.hex() %>', m.get('themeColor', '#000000'))
template = template.replace('<%= themeColorDark.hex() %>', '#000000')
template = template.replace('<%= navigationColor.hex() %>', '#000000')
template = template.replace('<%= navigationColorDark.hex() %>', '#000000')
template = template.replace('<%= navigationDividerColor.hex() %>', '#00000000')
template = template.replace('<%= navigationDividerColorDark.hex() %>', '#00000000')
template = template.replace('<%= backgroundColor.hex() %>', m.get('backgroundColor', '#0d0d0d'))
template = template.replace('<%= enableNotifications %>', 'false')
template = template.replace('<%= generateShortcuts() %>', '[]')
template = template.replace('<%= splashScreenFadeOutDuration %>', str(m.get('splashScreenFadeOutDuration', 0)))
template = template.replace('<%= generatorApp %>', 'bubblewrap-cli')
template = template.replace('<%= fallbackType %>', m.get('fallbackType', 'customtabs'))
template = template.replace('<%= enableSiteSettingsShortcut %>', 'true')
template = template.replace('<%= orientation %>', 'portrait')
template = template.replace('<%= minSdkVersion %>', '21')
template = template.replace('<%= appVersionCode %>', str(m.get('appVersionCode', 1)))
template = template.replace('<%= appVersionName %>', m.get('appVersionName', '1.0'))

# Handle conditional blocks - remove unneeded ones
import re
template = re.sub(r'<% if \(launchHandlerClientMode\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = re.sub(r'<% if \(webManifestUrl\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = re.sub(r'<% if \(fullScopeUrl\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = re.sub(r'<% if \(shareTarget\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = re.sub(r'<% for\(const config of buildGradle\.configs\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = re.sub(r'<% for\(const rep of buildGradle\.repositories\) \{ %>.*?<% \} %>', '', template, flags=re.DOTALL)
template = template.replace("""<% for(const dep of buildGradle.dependencies) { %>
        implementation '<%= dep %>'
    <% } %>""", "    implementation 'com.google.androidbrowserhelper:locationdelegation:1.0.0'\n    implementation 'com.google.androidbrowserhelper:androidbrowserhelper:2.5.0'")

with open('app/build.gradle', 'w') as f:
    f.write(template)

# Create AndroidManifest
manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/appName"
        android:supportsRtl="true"
        android:theme="@style/Theme.LauncherActivity">

        <activity android:name="{pkg}.LauncherActivity"
            android:exported="true"
            android:configChanges="keyboard|keyboardHidden|orientation|screenSize|screenLayout|smallestScreenSize|uiMode"
            android:launchMode="singleTop">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https"
                    android:host="{host}" />
            </intent-filter>

            <meta-data android:name="android.support.customtabs.trusted.asset_statements"
                android:resource="@string/assetStatements" />
        </activity>

        <service
            android:name="{pkg}.DelegationService"
            android:enabled="false"
            android:exported="false">
            <meta-data android:name="android.support.customtabs.trusted.FILE_PROVIDER_AUTHORITY"
                android:value="@string/providerAuthority" />
        </service>
    </application>
</manifest>'''

os.makedirs('app/src/main', exist_ok=True)
with open('app/src/main/AndroidManifest.xml', 'w') as f:
    f.write(manifest)

# Create strings.xml
import hashlib
fingerprint = hashlib.sha256(f"CN=HellSetlog".encode()).hexdigest().upper()
strings = f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="appName">{m['name']}</string>
    <string name="launcherName">{m['launcherName']}</string>
    <string name="launchUrl">https://{host}{m.get('startUrl', '/')}</string>
    <string name="hostName">{host}</string>
    <string name="providerAuthority">{pkg}.fileprovider</string>
    <string name="assetStatements">[{{"relation": ["delegate_permission/common.handle_all_urls"], "target": {{"namespace": "web", "site": "https://{host}"}}}}]</string>
</resources>'''

os.makedirs('app/src/main/res/values', exist_ok=True)
os.makedirs('app/src/main/res/xml', exist_ok=True)
os.makedirs('app/src/main/res/mipmap-hdpi', exist_ok=True)

with open('app/src/main/res/values/strings.xml', 'w') as f:
    f.write(strings)

# Create colors.xml
colors = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#0d0d0d</color>
    <color name="colorPrimaryDark">#000000</color>
    <color name="navigationColor">#000000</color>
    <color name="navigationColorDark">#000000</color>
    <color name="navigationDividerColor">#00000000</color>
    <color name="navigationDividerColorDark">#00000000</color>
    <color name="backgroundColor">#0d0d0d</color>
</resources>'''
with open('app/src/main/res/values/colors.xml', 'w') as f:
    f.write(colors)

# Create empty shortcuts.xml
with open('app/src/main/res/xml/shortcuts.xml', 'w') as f:
    f.write('<shortcuts xmlns:android="http://schemas.android.com/apk/res/android" />')

# Create LauncherActivity.java
java_dir = f'app/src/main/java/{pkg.replace(".", "/")}'
os.makedirs(java_dir, exist_ok=True)

launcher = f'''package {pkg};

import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import androidx.annotation.Nullable;
import com.google.androidbrowserhelper.trusted.LauncherActivity;
import com.google.androidbrowserhelper.trusted.DelegationService;

public class LauncherActivity extends com.google.androidbrowserhelper.trusted.LauncherActivity {{
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {{
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {{
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        }}
    }}

    @Override
    protected Uri getLaunchingUrl() {{
        Uri uri = super.getLaunchingUrl();
        return uri;
    }}
}}
'''

with open(f'{java_dir}/LauncherActivity.java', 'w') as f:
    f.write(launcher)

# Create DelegationService.java
with open(f'{java_dir}/DelegationService.java', 'w') as f:
    f.write(f'''package {pkg};

import com.google.androidbrowserhelper.trusted.DelegationService;

public class DelegationService extends DelegationService {{ }}
''')

# Create res/values/styles.xml
os.makedirs('app/src/main/res/values', exist_ok=True)
with open('app/src/main/res/values/styles.xml', 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.LauncherActivity" parent="Theme.AppCompat.NoActionBar">
        <item name="android:statusBarColor">@color/colorPrimary</item>
        <item name="android:navigationBarColor">@color/navigationColor</item>
    </style>
</resources>''')

# Create local.properties
with open('local.properties', 'w') as f:
    f.write(f'sdk.dir=/mnt/c/Users/john/AppData/Local/Android/Sdk\n')

# Create settings.gradle
with open('settings.gradle', 'w') as f:
    f.write('''pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "HellSetlog"
include ':app'
''')

# Create project build.gradle
with open('build.gradle', 'w') as f:
    f.write('''plugins {
    id 'com.android.application' version '8.7.3' apply false
}
''')

# Create gradle.properties
with open('gradle.properties', 'w') as f:
    f.write('''org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
''')

print("DONE - project configured")
print(f"PACKAGE={pkg}")
print(f"HOST={host}")
