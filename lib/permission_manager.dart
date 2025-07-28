import "package:permission_handler/permission_handler.dart";
import "package:fluttertoast/fluttertoast.dart";

Future<void> checkAudioPermission() async {
  try {
    PermissionStatus audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) {
    } else if (audioStatus.isPermanentlyDenied) {
      await Fluttertoast.showToast(
        msg: "请手动授予应用读取音频文件的权限",
      );
      openAppSettings();
    } else {
      await Fluttertoast.showToast(
        msg: "请授予应用读取音频文件的权限",
      );
    }
  } catch (e) {
    print("获取音频权限失败: $e");
  }
}

Future<bool> checkWritingPermission() async {
  try {
    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await Fluttertoast.showToast(
        msg: "请手动授予应用管理文件的权限",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      openAppSettings();
      return false;
    } else {
      await Fluttertoast.showToast(
        msg: "请授予应用管理文件的权限",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
  } catch (e) {
    print("获取文件操作权限失败: $e");
    return false;
  }
}
