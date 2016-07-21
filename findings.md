# Database

The database has only one table called `LSQuarantineEvent`.

Each entry has the following fields:

| Field                               | Description                                                                      |
| ----------------------------------- | -------------------------------------------------------------------------------- |
| `LSQuarantineEventIdentifier`       | UUID                                                                             |
| `LSQuarantineTimeStamp`             | Unix time as float with 6 decimal places, offset by -978307200 (January 1, 2001) |
| `LSQuarantineAgentBundleIdentifier` | Bundle ID of the application that was used to download the file                  |
| `LSQuarantineAgentName`             | Name of the application that was used to download the file (shown in dialog)     |
| `LSQuarantineDataURLString`         | URL from which the file was downloaded                                           |
| `LSQuarantineSenderName`            |                                                                                  |
| `LSQuarantineSenderAddress`         |                                                                                  |
| `LSQuarantineTypeNumber`            | number of quarantine type                                                          |
| `LSQuarantineOriginTitle`           |                                                                                  |
| `LSQuarantineOriginURLString`       | URL of the page which referred to the download URL (shown in dialog)             |
| `LSQuarantineOriginAlias`           |                                                                                  |


# Extended Attribute

A `com.apple.quarantine` attribute has 4 fields:

| Field                         | Description                                                                                                      |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `LSQuarantineType`            | Does not exactly correspond to `LSQuarantineTypeNumber`, but the last digit has some kind of relationship to it. |
| `LSQuarantineTimeStamp`       | Unix time as a hex string.                                                                                       |
| `LSQuarantineAgentName`       | Name of the application that was used to download the file.                                                      |
| `LSQuarantineEventIdentifier` | UUID                                                                                                             |

## Behaviour

When extracted using `xattr -p com.apple.quarantine`  ,

 - on **Applications,**  
   the number in the first field is or'd with `0x40` when the “Do you want to open …?” dialog is accepted.  
   The dialog is only shown and the number is only changed if it is less than `0x40`.
 
   Examples:
   
   <code>00<b>0</b>2</code> ⇒ <code>00<b>4</b>2</code>  
   <code>00<b>1</b>2</code> ⇒ <code>00<b>5</b>2</code>  
   <code>00<b>2</b>2</code> ⇒ <code>00<b>6</b>2</code>  
   <code>00<b>3</b>2</code> ⇒ <code>00<b>7</b>2</code>  
   
 - on **PKG and MPKG Installers,**  
   the number in the first field is or'd with `0x20` when the installer is opened (no dialog is shown).  
   The number is only changed if it is less than `0x20`.
   
   Examples:
   
   <code>00<b>0</b>2</code> ⇒ <code>00<b>2</b>2</code>  
   <code>00<b>1</b>2</code> ⇒ <code>00<b>3</b>2</code>  

---

Before accepting the “Do you want to open …?” dialog:

```shell
$ xattr -p com.apple.quarantine Application.app
0002;57925626;Safari;AB93505D-FD4F-4E94-A463-28D82C8B6D71
```

After accepting the “Do you want to open …?” dialog:
 
```shell
$ xattr -p com.apple.quarantine Application.app
0042;57925626;Safari;AB93505D-FD4F-4E94-A463-28D82C8B6D71
```
 
 