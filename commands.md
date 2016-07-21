
**Read `com.apple.metadata:kMDItemWhereFroms`**

    /usr/bin/xattr -p com.apple.metadata:kMDItemWhereFroms "${file}" | /usr/bin/xxd -r -p | /usr/bin/plutil -convert xml1 -o - -


**Set `com.apple.metadata:kMDItemWhereFroms`**

    url="http://example.com"
    hexdump=$(echo "<plist><array><string>${url}</string></array></plist>" | /usr/bin/plutil -convert binary1 -o - - | /usr/bin/xxd -p | /usr/bin/tr -d "\n")
    /usr/bin/xattr -w com.apple.metadata:kMDItemWhereFroms "${hexdump}" "${file}"


**Read `com.apple.metadata:kMDItemDownloadedDate`**

    /usr/bin/xattr -p com.apple.metadata:kMDItemDownloadedDate "${file}" | /usr/bin/xxd -r -p | /usr/bin/plutil -convert xml1 -o - -


**Set `com.apple.metadata:kMDItemDownloadedDate`**

    date=$(date +%Y-%m-%dT%H:%M:%SZ)
    hexdump=$(echo "<plist><array><date>${date}</date></array></plist>" | /usr/bin/plutil -convert binary1 -o - - | /usr/bin/xxd -p | /usr/bin/tr -d "\n")
    /usr/bin/xattr -w com.apple.metadata:kMDItemDownloadedDate "${hexdump}" "${file}"


**Read `com.apple.quarantine`**

    /usr/bin/xattr -p com.apple.quarantine "${file}"

**Set `com.apple.quarantine`**

    application="cURL"
    date=$(printf %x $(date +%s))
    uuid=$(/usr/bin/uuidgen)
    /usr/bin/xattr -w com.apple.quarantine "0002;${date};${application};${uuid}" "${file}"

**Insert UUID into Database**

    download_url="http://example.com/file.zip"
    date=$(($(date +%s) - 978307200))
    /usr/bin/sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2 \
      "INSERT INTO \"LSQuarantineEvent\" VALUES('${uuid}',${date},NULL,'${application}','${download_url}',NULL,NULL,0,NULL,'${url}',NULL);"

**Check if UUID exists in Database**

    /usr/bin/sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2 \
      "SELECT * FROM LSQuarantineEvent WHERE LSQuarantineEventIdentifier == '${uuid}'"
