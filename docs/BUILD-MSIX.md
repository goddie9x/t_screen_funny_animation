# Build MSIX cho TScreen Funny Animation

Workflow `.github/workflows/msix.yml` (từ template `msix-flutter-standalone`):

- Trigger: Actions → MSIX → Run workflow, nhập version X.Y.Z (vd 0.1.0),
  hoặc push tag `msix-v*`.
- Runner build: `flutter build windows --release` → đóng gói MSIX unsigned.
- Artifact: `t-screen-funny-animation-<version>.msix`.
- Identity: `goddie9x.TScreenFunnyAnimation`, Publisher `CN=8633D8C8-01ED-4486-B41B-1CD6E3B8F80D`,
  PublisherDisplayName `goddie9x` (đã reserve trên Partner Center).
- Nộp Store: upload file .msix lên Partner Center (draft submission),
  điền listing/screenshot/privacy policy rồi submit kiểm duyệt.
