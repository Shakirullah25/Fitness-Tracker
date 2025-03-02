import 'dart:async';
import 'package:fitness_tracker/mock_fitness_data.dart';

import 'database_helper.dart';
import 'notification_service.dart';
import 'stat_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';



MockFitnessData generateMockData() {
  return MockFitnessData(
    steps: 5000 + DateTime.now().second, // Simulate step count
    caloriesBurned:
        300.0 + DateTime.now().second / 10, // Simulate calories burned
    heartRate: 72 + DateTime.now().second % 10, // Simulate heart rate
  );
}

class FitnessTrackerHomePage extends StatefulWidget {
  const FitnessTrackerHomePage({super.key});

  @override
  State<FitnessTrackerHomePage> createState() => _FitnessTrackerHomePageState();
}

class _FitnessTrackerHomePageState extends State<FitnessTrackerHomePage> {
  int stepCount = 0;
  double caloriesBurned = 0.0;
  int heartRate = 72;
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  List<BluetoothDevice> foundDevices = [];
  late Timer _mockDataTimer;
  final dbHelper = DatabaseHelper();
  final NotificationService notificationService = NotificationService();

  // Future<void> _initializeNotification() async {
  //   await notificationService.init();
  //   notificationService.scheduleDailyReminder();
  // }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    notificationService.init(); // _initializeNotification();
    notificationService.scheduleDailyReminder();
    _startMockDataStream(); // Start mock data stream
    loadFitnessData(); // Loading saved data when the app initializes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkBluetoothState();
  }

  @override
  void dispose() {
    _mockDataTimer.cancel(); // Stop mock data stream
    disconnectDevice();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

  Future<void> checkBluetoothState() async {
    if (!await FlutterBluePlus.isSupported) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Bluetooth is not available on this device.");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Bluetooth is not turned on. Turning it on...");
      await FlutterBluePlus.turnOn();
    } else {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Bluetooth is already on.");
    }
  }

  Future<void> scanForDevices() async {
    await checkBluetoothState();

    if (!mounted) return;
    setState(() => isScanning = true);

    try {
      // Simulate device discovery
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate scanning delay

      // Create a mock BluetoothDevice using the correct constructor
      final mockDevice = BluetoothDevice(
        remoteId: const DeviceIdentifier("mock-device-id"), // Use a mock device ID
      );

      setState(() {
        foundDevices.add(mockDevice);
      });

      // Simulate connecting to the mock device
      await connectToDevice(mockDevice);
    } catch (e) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Error during scan: $e");
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Simulate connection
      showSnackBar(context, "Connected to ${device.remoteId}");
      if (mounted) {
        setState(() => connectedDevice = device);
      }
    } catch (e) {
      showSnackBar(context, "Error connecting to device: $e");
    }
  }

  void _startMockDataStream() {
    _mockDataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final mockData = generateMockData();
      if (mounted) {
        setState(() {
          stepCount = mockData.steps;
          caloriesBurned = mockData.caloriesBurned;
          heartRate = mockData.heartRate;
        });

        // Save mock data to SQLite
        dbHelper.insertFitnessData(
          mockData.steps,
          mockData.caloriesBurned,
          mockData.heartRate,
        );
      }
    });
  }

  void loadFitnessData() async {
    final data = await dbHelper.getFitnessData();
    if (data.isNotEmpty) {
      setState(() {
        stepCount = data.last['steps'];
        caloriesBurned = data.last['caloriesBurned'];
        heartRate = data.last['heartRate'];
      });
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        if (mounted) {
          setState(() => connectedDevice = null);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        showSnackBar(context, "Error disconnecting device: $e");
      }
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        title: const Text(
          'Fitness Tracker',
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.fitness_center,
                size: 23,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  isScanning
                      ? "Scanning..."
                      : "Connected Device: ${connectedDevice?.remoteId ?? "None"}",
                  style: TextStyle(
                    color: isScanning ? Colors.grey : Colors.black,
                    fontSize: 20,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.only(top: 40),
                      width: double.infinity,
                      //height: size.height,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(90),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 70),
                            ElevatedButton(
                              onPressed: () => scanForDevices(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                "Scan Bluetooth Device",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () {
                                notificationService.showTestNotification();
                              },
                              child: const Text("Test Notification",
                              style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildStatContainter(
                              size,
                              title: 'Steps',
                              value: stepCount.toString(),
                              icon: Icons.directions_walk,
                              color: Colors.blue.shade50,
                              widthFactor: 0.5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: buildStatContainter(
                                    size,
                                    title: 'Calories Burned',
                                    value:
                                        "${caloriesBurned.toStringAsFixed(1)} kcal",
                                    icon: Icons.local_fire_department,
                                    color: Colors.red.shade50,
                                    widthFactor: 3,
                                    topSpacing: 70,
                                    bottomSpacing: 50,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: buildStatContainter(
                                    size,
                                    title: "Heart Rate",
                                    value: "$heartRate bpm",
                                    icon: Icons.favorite,
                                    color: Colors.green.shade50,
                                    widthFactor: 3,
                                    topSpacing: 70,
                                    bottomSpacing: 50,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
