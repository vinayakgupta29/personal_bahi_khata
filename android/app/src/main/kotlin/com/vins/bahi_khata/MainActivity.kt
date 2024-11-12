
package com.vins.bahi_khata


import android.content.Intent
import android.os.Bundle
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.Manifest
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat




class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.vins.bahi_khata/open_file"

    var openPath: String? = null
    private val fileProvider = "com.vins.bahi_khata.fileprovider"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "handleOpenFileUrl" -> {
                    println("openPath $openPath")
                    result.success(openPath)
                }
                "isTelephonyAvailable" -> {
                    val isAvailable = isTelephonyAvailable()
                    result.success(isAvailable)
                }
                else -> result.notImplemented()
            }
        }


    
//      val channel2 =  MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vins.bahi_khata/write_file")
//      channel2.setMethodCallHandler { call, result ->
//            when (call.method) {
//                "writeToFile" -> {
//                    val args = call.arguments as? Map<String, String>
//                    val fileName = args?.get("fileName")
//                    val content = args?.get("content")
//                    if (fileName != null && content != null) {
//                        writeToFile(this,fileName, content)
//                        result.success(fileName)
//                    } else {
//                        result.error("INVALID_ARGUMENTS", "File name or content is null", null)
//                    }
//                }
//                else -> {
//                    result.notImplemented()
//                }
//            }
//        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleOpenFileUrl(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleOpenFileUrl(intent)
    }
    
    private fun handleOpenFileUrl(intent: Intent?) {

        val path = intent?.data?.path
        if (path != null) {
            openPath = path.substring(5) // Adjust the substring index based on your file URI format
            println("path: $path")
        }
    }

    private fun isTelephonyAvailable(): Boolean {
        val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        return telephonyManager.phoneType != TelephonyManager.PHONE_TYPE_NONE
    }

    
    

//    private fun writeToFile(context: Context, fileName: String, jsonData: String) {
//
//        val root = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
//        println(root)
//        // Specify the subfolder name
//        val subfolderName = "Personal Bahi Khata"
//        // Create a File object representing the subfolder
//        val subfolder = File(root, subfolderName)
//        // Create the subfolder if it doesn't exist
//        if (!subfolder.exists()) {
//            subfolder.mkdirs() // Create directories recursively
//        }
//        // Create the file in the subfolder
//        val file = File(subfolder, fileName + ".bkx")
//
//        val _fileProvider = FileProvider.getUriForFile(context, fileProvider, file)
//
//        val contentResolver = context.contentResolver
//
//
//        try {
//          val outputStream = context.contentResolver.openOutputStream(_fileProvider)
//          if (outputStream != null) {
//            outputStream.write(jsonData.toByteArray())
//            outputStream.close()
//            println(File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), fileName + ".bkx"))
//            println("File written successfully:")
//            println("Path: $fileProvider")
//            println("MIME Type: application/vnd.com.vins.bhi_khata.bkx")
//
//        // Get MIME type
//        val mimeType = contentResolver.getType(_fileProvider)
//
//        println("meme : $mimeType")
//          }
//        } catch (e: Exception) {
//          println("FileWritingErrorError writing to file:$e")
//        }
//      }
      
    
}
