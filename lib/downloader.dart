// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class VideoDownloader extends StatefulWidget {
//   @override
//   _VideoDownloaderState createState() => _VideoDownloaderState();
// }
//
// class _VideoDownloaderState extends State<VideoDownloader> {
//   final TextEditingController _urlController = TextEditingController();
//   final YoutubeExplode _yt = YoutubeExplode();
//   bool _isLoading = false;
//   bool _isDownloading = false;
//   double _downloadProgress = 0.0;
//   String _status = '';
//   List<_VideoQuality> _availableQualities = [];
//   _VideoQuality? _selectedQuality;
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
//   List<_DownloadItem> _downloadHistory = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initNotifications();
//     _loadDownloadHistory();
//   }
//
//   @override
//   void dispose() {
//     _yt.close();
//     _urlController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadDownloadHistory() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? history = prefs.getStringList('download_history');
//     if (history != null) {
//       setState(() {
//         _downloadHistory = history
//             .map((item) {
//           final parts = item.split('|');
//           if (parts.length >= 3) {
//             return _DownloadItem(
//               title: parts[0],
//               path: parts[1],
//               timestamp: DateTime.parse(parts[2]),
//               source: parts.length > 3 ? parts[3] : 'Unknown',
//             );
//           }
//           return null;
//         })
//             .whereType<_DownloadItem>()
//             .toList();
//       });
//     }
//   }
//
//   Future<void> _saveDownloadHistory() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> history = _downloadHistory
//         .map((item) => '${item.title}|${item.path}|${item.timestamp.toIso8601String()}|${item.source}')
//         .toList();
//     await prefs.setStringList('download_history', history);
//   }
//
//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     final DarwinInitializationSettings initializationSettingsIOS =
//     DarwinInitializationSettings();
//
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//
//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse details) {
//         // Handle notification tapped logic
//       },
//     );
//   }
//
//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       var status = await Permission.storage.status;
//       if (!status.isGranted) {
//         status = await Permission.storage.request();
//         if (!status.isGranted) {
//           throw Exception('Storage permission denied');
//         }
//       }
//
//       // For Android 10+
//       if (await Permission.manageExternalStorage.isDenied) {
//         await Permission.manageExternalStorage.request();
//       }
//     }
//   }
//
//   Future<void> _fetchVideoInfo() async {
//     String url = _urlController.text.trim();
//     if (url.isEmpty) {
//       _showSnackBar('Please enter a valid URL');
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _status = 'Fetching video information...';
//       _availableQualities = [];
//       _selectedQuality = null;
//     });
//
//     try {
//       if (_isYouTubeUrl(url)) {
//         await _fetchYouTubeQualities(url);
//       } else if (_isFacebookUrl(url)) {
//         await _fetchFacebookQualities(url);
//       } else {
//         _showSnackBar('Unsupported URL. Only YouTube and Facebook are supported.');
//       }
//     } catch (e) {
//       _showSnackBar('Error fetching video info: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   bool _isYouTubeUrl(String url) {
//     return url.contains('youtube.com') || url.contains('youtu.be');
//   }
//
//   bool _isFacebookUrl(String url) {
//     return url.contains('facebook.com') || url.contains('fb.watch');
//   }
//
//   Future<void> _fetchYouTubeQualities(String url) async {
//     try {
//       // Get video ID
//       Video video = await _yt.videos.get(url);
//
//       // Get manifest and streams
//       StreamManifest manifest = await _yt.videos.streamsClient.getManifest(video.id);
//
//       // Get available video qualities
//       List<VideoStreamInfo> videoStreams = manifest.videoOnly.toList();
//       videoStreams.sort((a, b) => b.videoQuality.compareTo(a.videoQuality));
//
//       // Also get muxed streams (video+audio)
//       List<MuxedStreamInfo> muxedStreams = manifest.muxed.toList();
//       muxedStreams.sort((a, b) => b.videoQuality.compareTo(a.videoQuality));
//
//       List<_VideoQuality> qualities = [];
//
//       // Add video-only streams
//       for (var stream in videoStreams) {
//         qualities.add(_VideoQuality(
//           quality: '${stream.videoQuality.name} (${stream.videoResolution}) - Video Only',
//           url: stream.url.toString(),
//           container: stream.container.name,
//           fileSize: stream.size.totalBytes,
//           streamInfo: stream,
//           isAudioOnly: false,
//           videoTitle: video.title,
//           source: 'YouTube',
//         ));
//       }
//
//       // Add muxed streams (video+audio)
//       for (var stream in muxedStreams) {
//         qualities.add(_VideoQuality(
//           quality: '${stream.videoQuality.name} (${stream.videoResolution}) - with Audio',
//           url: stream.url.toString(),
//           container: stream.container.name,
//           fileSize: stream.size.totalBytes,
//           muxedStreamInfo: stream,
//           isAudioOnly: false,
//           videoTitle: video.title,
//           source: 'YouTube',
//         ));
//       }
//
//       // Audio only option
//       var audioStream = manifest.audioOnly.withHighestBitrate();
//       qualities.add(_VideoQuality(
//         quality: 'Audio Only (${audioStream.bitrate.kiloBitsPerSecond} kbps)',
//         url: audioStream.url.toString(),
//         container: audioStream.container.name,
//         fileSize: audioStream.size.totalBytes,
//         audioStreamInfo: audioStream,
//         isAudioOnly: true,
//         videoTitle: video.title,
//         source: 'YouTube',
//       ));
//
//       setState(() {
//         _availableQualities = qualities;
//         _selectedQuality = qualities.first;
//         _status = 'Selected video: ${video.title}';
//       });
//     } catch (e) {
//       _showSnackBar('Error getting YouTube video: $e');
//     }
//   }
//
//   Future<void> _fetchFacebookQualities(String url) async {
//     _showSnackBar('Facebook video downloading is experimental and may not work for all videos');
//
//     setState(() {
//       _status = 'Facebook videos may require different handling. Basic quality options available.';
//       _availableQualities = [
//         _VideoQuality(
//           quality: 'HD (720p) - Experimental',
//           url: url,
//           container: 'mp4',
//           fileSize: 0,
//           isAudioOnly: false,
//           videoTitle: 'Facebook Video',
//           source: 'Facebook',
//         ),
//         _VideoQuality(
//           quality: 'SD (480p) - Experimental',
//           url: url,
//           container: 'mp4',
//           fileSize: 0,
//           isAudioOnly: false,
//           videoTitle: 'Facebook Video',
//           source: 'Facebook',
//         ),
//       ];
//       _selectedQuality = _availableQualities.first;
//     });
//   }
//
//   Future<void> _downloadVideo() async {
//     if (_selectedQuality == null) {
//       _showSnackBar('Please select a quality first');
//       return;
//     }
//
//     try {
//       await _requestPermissions();
//     } catch (e) {
//       _showSnackBar('Permission denied: $e');
//       return;
//     }
//
//     setState(() {
//       _isDownloading = true;
//       _downloadProgress = 0.0;
//       _status = 'Starting download...';
//     });
//
//     try {
//       final directory = await _getDownloadDirectory();
//       final fileName = _sanitizeFilename(
//           '${_selectedQuality!.videoTitle}_${_selectedQuality!.quality}.${_selectedQuality!.container}');
//       final filePath = path.join(directory.path, fileName);
//
//       // Check if file already exists
//       if (await File(filePath).exists()) {
//         final shouldOverwrite = await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text('File Exists'),
//             content: Text('A file with this name already exists. Overwrite?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text('Overwrite'),
//               ),
//             ],
//           ),
//         );
//
//         if (shouldOverwrite != true) {
//           setState(() {
//             _isDownloading = false;
//             _status = 'Download canceled';
//           });
//           return;
//         }
//       }
//
//       // Show initial notification
//       await _showProgressNotification(0, 'Starting download');
//
//       if (_selectedQuality!.source == 'YouTube') {
//         await _downloadYouTubeVideo(filePath);
//       } else if (_selectedQuality!.source == 'Facebook') {
//         await _downloadFacebookVideo(filePath);
//       }
//
//       // Add to download history
//       _downloadHistory.add(_DownloadItem(
//         title: _selectedQuality!.videoTitle,
//         path: filePath,
//         timestamp: DateTime.now(),
//         source: _selectedQuality!.source,
//       ));
//       await _saveDownloadHistory();
//
//       setState(() {
//         _status = 'Download complete: $filePath';
//       });
//
//       // Show completion notification
//       await _showCompletionNotification('Download complete', 'Video saved to Downloads folder');
//
//     } catch (e) {
//       _showSnackBar('Download error: $e');
//       await _showCompletionNotification('Download failed', 'Error: $e');
//     } finally {
//       setState(() {
//         _isDownloading = false;
//       });
//     }
//   }
//
//   Future<void> _downloadYouTubeVideo(String filePath) async {
//     try {
//       // For audio-only download
//       if (_selectedQuality!.isAudioOnly && _selectedQuality!.audioStreamInfo != null) {
//         var audioStream = _selectedQuality!.audioStreamInfo!;
//
//         // Create a stream for the audio
//         var stream = _yt.videos.streamsClient.get(audioStream);
//
//         // Open file for writing
//         var file = File(filePath);
//         var fileStream = file.openWrite();
//
//         // Track download size and progress
//         int totalBytes = audioStream.size.totalBytes;
//         int receivedBytes = 0;
//
//         // Download with progress tracking
//         await stream.pipe(
//           StreamTransformer<List<int>, List<int>>.fromHandlers(
//             handleData: (data, sink) {
//               receivedBytes += data.length;
//               double progress = receivedBytes / totalBytes;
//
//               setState(() {
//                 _downloadProgress = progress;
//                 _status = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
//               });
//
//               _updateProgressNotification(progress);
//               sink.add(data);
//             },
//           ),
//         ).pipe(fileStream);
//
//         await fileStream.flush();
//         await fileStream.close();
//         return;
//       }
//
//       // For video streams
//       if (_selectedQuality!.streamInfo != null) {
//         var videoStream = _selectedQuality!.streamInfo!;
//         var videoId = videoStream.id.videoId;
//
//         // For video-only streams, we need to also download audio and mux them
//         var manifest = await _yt.videos.streamsClient.getManifest(videoId);
//         var audioStream = manifest.audioOnly.withHighestBitrate();
//
//         // Download video stream
//         var videoStreamData = _yt.videos.streamsClient.get(videoStream);
//         var tempVideoPath = filePath + '.video';
//         var videoFile = File(tempVideoPath);
//         var videoFileStream = videoFile.openWrite();
//
//         // Download audio stream
//         var audioStreamData = _yt.videos.streamsClient.get(audioStream);
//         var tempAudioPath = filePath + '.audio';
//         var audioFile = File(tempAudioPath);
//         var audioFileStream = audioFile.openWrite();
//
//         // Track total size and progress
//         int totalSize = videoStream.size.totalBytes + audioStream.size.totalBytes;
//         int receivedBytes = 0;
//
//         // Download video with progress
//         await videoStreamData.pipe(
//           StreamTransformer<List<int>, List<int>>.fromHandlers(
//             handleData: (data, sink) {
//               receivedBytes += data.length;
//               double progress = receivedBytes / totalSize;
//
//               setState(() {
//                 _downloadProgress = progress * 0.5; // Video is first half of progress
//                 _status = 'Downloading video: ${(progress * 100).toStringAsFixed(1)}%';
//               });
//
//               _updateProgressNotification(progress * 0.5);
//               sink.add(data);
//             },
//           ),
//         ).pipe(videoFileStream);
//
//         await videoFileStream.flush();
//         await videoFileStream.close();
//
//         // Download audio with progress
//         receivedBytes = 0;
//         await audioStreamData.pipe(
//           StreamTransformer<List<int>, List<int>>.fromHandlers(
//             handleData: (data, sink) {
//               receivedBytes += data.length;
//               double progress = receivedBytes / audioStream.size.totalBytes;
//
//               setState(() {
//                 _downloadProgress = 0.5 + (progress * 0.3); // Audio is next 30% of progress
//                 _status = 'Downloading audio: ${(progress * 100).toStringAsFixed(1)}%';
//               });
//
//               _updateProgressNotification(0.5 + (progress * 0.3));
//               sink.add(data);
//             },
//           ),
//         ).pipe(audioFileStream);
//
//         await audioFileStream.flush();
//         await audioFileStream.close();
//
//         // Now mux them together (in a real app, you'd use FFmpeg for this)
//         setState(() {
//           _downloadProgress = 0.8;
//           _status = 'Processing video and audio...';
//         });
//         _updateProgressNotification(0.8);
//
//         // Simplified implementation - in a real app you'd use FFmpeg
//         // FFmpeg code would go here to mux the files
//
//         // For this example, we'll just copy the video file to the destination
//         await videoFile.copy(filePath);
//
//         // Clean up temp files
//         await videoFile.delete();
//         await audioFile.delete();
//
//         setState(() {
//           _downloadProgress = 1.0;
//         });
//         _updateProgressNotification(1.0);
//
//         return;
//       }
//
//       // For muxed streams (video+audio together)
//       if (_selectedQuality!.muxedStreamInfo != null) {
//         var muxedStream = _selectedQuality!.muxedStreamInfo!;
//
//         // Create a stream for the video
//         var stream = _yt.videos.streamsClient.get(muxedStream);
//
//         // Open file for writing
//         var file = File(filePath);
//         var fileStream = file.openWrite();
//
//         // Track download size and progress
//         int totalBytes = muxedStream.size.totalBytes;
//         int receivedBytes = 0;
//
//         // Download with progress tracking
//         await stream.pipe(
//           StreamTransformer<List<int>, List<int>>.fromHandlers(
//             handleData: (data, sink) {
//               receivedBytes += data.length;
//               double progress = receivedBytes / totalBytes;
//
//               setState(() {
//                 _downloadProgress = progress;
//                 _status = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
//               });
//
//               _updateProgressNotification(progress);
//               sink.add(data);
//             },
//           ),
//         ).pipe(fileStream);
//
//         await fileStream.flush();
//         await fileStream.close();
//       }
//     } catch (e) {
//       await _cleanupPartialDownloads(filePath);
//       rethrow;
//     }
//   }
//
//   Future<void> _cleanupPartialDownloads(String filePath) async {
//     try {
//       final file = File(filePath);
//       if (await file.exists()) await file.delete();
//
//       final tempVideo = File('$filePath.video');
//       if (await tempVideo.exists()) await tempVideo.delete();
//
//       final tempAudio = File('$filePath.audio');
//       if (await tempAudio.exists()) await tempAudio.delete();
//     } catch (e) {
//       debugPrint('Error cleaning up files: $e');
//     }
//   }
//
//   Future<void> _downloadFacebookVideo(String filePath) async {
//     try {
//       final response = await http.get(Uri.parse(_selectedQuality!.url));
//       final bytes = response.bodyBytes;
//       final file = File(filePath);
//
//       // Simulate download progress
//       final totalBytes = bytes.length;
//       int writtenBytes = 0;
//       final chunkSize = totalBytes ~/ 100; // Split into 100 chunks for progress updates
//
//       final fileStream = file.openWrite();
//
//       for (int i = 0; i < totalBytes; i += chunkSize) {
//         final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
//         final chunk = bytes.sublist(i, end);
//
//         fileStream.add(chunk);
//         writtenBytes += chunk.length;
//
//         final progress = writtenBytes / totalBytes;
//         setState(() {
//           _downloadProgress = progress;
//           _status = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
//         });
//
//         await _updateProgressNotification(progress);
//
//         // Simulate network delay
//         await Future.delayed(Duration(milliseconds: 50));
//       }
//
//       await fileStream.flush();
//       await fileStream.close();
//
//       setState(() {
//         _downloadProgress = 1.0;
//         _status = 'Download complete';
//       });
//
//       await _updateProgressNotification(1.0);
//     } catch (e) {
//       await _cleanupPartialDownloads(filePath);
//       throw Exception('Failed to download Facebook video: $e');
//     }
//   }
//
//   Future<Directory> _getDownloadDirectory() async {
//     Directory? directory;
//
//     if (Platform.isAndroid) {
//       directory = Directory('/storage/emulated/0/Download');
//       // Ensure the directory exists
//       if (!await directory.exists()) {
//         directory = await getExternalStorageDirectory();
//       }
//     } else {
//       directory = await getApplicationDocumentsDirectory();
//     }
//
//     if (directory == null) {
//       throw Exception('Could not access storage directory');
//     }
//
//     return directory;
//   }
//
//   String _sanitizeFilename(String fileName) {
//     return fileName
//         .replaceAll(r'\', '')
//         .replaceAll('/', '')
//         .replaceAll('*', '')
//         .replaceAll(':', '')
//         .replaceAll('?', '')
//         .replaceAll('"', '')
//         .replaceAll('<', '')
//         .replaceAll('>', '')
//         .replaceAll('|', '')
//         .replaceAll(' ', '_');
//   }
//
//   Future<void> _showProgressNotification(double progress, String status) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'download_channel',
//       'Video Downloads',
//       channelDescription: 'Shows progress of video downloads',
//       importance: Importance.low,
//       priority: Priority.low,
//       showProgress: true,
//       maxProgress: 100,
//       progress: 0,
//       ongoing: true,
//       autoCancel: false,
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );
//
//     await _notificationsPlugin.show(
//       0,
//       'Downloading Video',
//       status,
//       notificationDetails,
//     );
//   }
//
//   Future<void> _updateProgressNotification(double progress) async {
//     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'download_channel',
//       'Video Downloads',
//       channelDescription: 'Shows progress of video downloads',
//       importance: Importance.low,
//       priority: Priority.low,
//       showProgress: true,
//       maxProgress: 100,
//       progress: (progress * 100).toInt(),
//       ongoing: true,
//       autoCancel: false,
//     );
//
//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );
//
//     await _notificationsPlugin.show(
//       0,
//       'Downloading Video',
//       '${(progress * 100).toInt()}% complete',
//       notificationDetails,
//     );
//   }
//
//   Future<void> _showCompletionNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'download_channel',
//       'Video Downloads',
//       channelDescription: 'Shows progress of video downloads',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );
//
//     await _notificationsPlugin.show(
//       1,
//       title,
//       body,
//       notificationDetails,
//     );
//   }
//
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Downloader'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _urlController,
//               decoration: InputDecoration(
//                 labelText: 'YouTube or Facebook Video URL',
//                 border: OutlineInputBorder(),
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.clear),
//                   onPressed: () => _urlController.clear(),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _fetchVideoInfo,
//                     child: Text('Fetch Video Info'),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _availableQualities.isNotEmpty
//                 ? Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Available Qualities:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 SizedBox(height: 8),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<_VideoQuality>(
//                       isExpanded: true,
//                       value: _selectedQuality,
//                       items: _availableQualities.map((quality) {
//                         String sizeText = quality.fileSize > 0
//                             ? ' (${(quality.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)'
//                             : '';
//                         return DropdownMenuItem(
//                           value: quality,
//                           child: Text('${quality.quality}$sizeText'),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedQuality = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _isDownloading ? null : _downloadVideo,
//                         child: Text('Download'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             )
//                 : SizedBox(),
//             SizedBox(height: 16),
//             if (_isDownloading) ...[
//               LinearProgressIndicator(value: _downloadProgress),
//               SizedBox(height: 8),
//               Text(_status),
//             ],
//             SizedBox(height: 24),
//             Expanded(
//               child: _downloadHistory.isEmpty
//                   ? Center(child: Text('No download history'))
//                   : Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Download History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                   SizedBox(height: 8),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: _downloadHistory.length,
//                       itemBuilder: (context, index) {
//                         final item = _downloadHistory[_downloadHistory.length - 1 - index];
//                         return ListTile(
//                           title: Text(item.title),
//                           subtitle: Text('${item.source} • ${_formatDate(item.timestamp)}'),
//                           leading: Icon(_getIconForSource(item.source)),
//                           trailing: IconButton(
//                             icon: Icon(Icons.play_arrow),
//                             onPressed: () {
//                               _showSnackBar('Playing video: ${item.title}');
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
//
//   IconData _getIconForSource(String source) {
//     switch (source) {
//       case 'YouTube':
//         return Icons.video_library;
//       case 'Facebook':
//         return Icons.facebook;
//       default:
//         return Icons.file_download;
//     }
//   }
// }
//
// class _VideoQuality {
//   final String quality;
//   final String url;
//   final String container;
//   final int fileSize;
//   final VideoStreamInfo? streamInfo;
//   final MuxedStreamInfo? muxedStreamInfo;
//   final AudioStreamInfo? audioStreamInfo;
//   final bool isAudioOnly;
//   final String videoTitle;
//   final String source;
//
//   _VideoQuality({
//     required this.quality,
//     required this.url,
//     required this.container,
//     required this.fileSize,
//     this.streamInfo,
//     this.muxedStreamInfo,
//     this.audioStreamInfo,
//     required this.isAudioOnly,
//     required this.videoTitle,
//     required this.source,
//   });
// }
//
// class _DownloadItem {
//   final String title;
//   final String path;
//   final DateTime timestamp;
//   final String source;
//
//   _DownloadItem({
//     required this.title,
//     required this.path,
//     required this.timestamp,
//     required this.source,
//   });
// }