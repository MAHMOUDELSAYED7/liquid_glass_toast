import 'package:flutter/material.dart';

import 'core/widgets/liquid_glass_toast.dart';

void main() {
  // Optional: customize the toast look once, app-wide. Any type or field
  // left out keeps the built-in default.
  LiquidGlassToast.configure(
    const LiquidGlassToastTheme(
      success: ToastTypeTheme(
        icon: Icons.thumb_up_rounded,
      ),
      error: ToastTypeTheme(icon: Icons.dangerous_rounded),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.title)),
      backgroundColor: Colors.black,

      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message: 'Saved successfully!',
                    type: ToastType.success,
                  ),
                  child: const Text('Success'),
                ),
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message: 'Something went wrong. Please try again.',
                    type: ToastType.error,
                  ),
                  child: const Text('Error'),
                ),
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message: 'This action cannot be undone.',
                    type: ToastType.warning,
                    position: ToastPosition.top,
                  ),
                  child: const Text('Warning'),
                ),
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message: 'A new update is available.',
                    type: ToastType.info,
                    position: ToastPosition.top,
                  ),
                  child: const Text('Info'),
                ),
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message:
                        'This is a multi-line toast message. It can be used to display longer messages that require more space. You can customize the appearance and behavior of the toast as needed.',
                    type: ToastType.error,
                  ),
                  child: const Text('Multi-line'),
                ),
                ElevatedButton(
                  onPressed: () => LiquidGlassToast.show(
                    context,
                    message:
                        'This is a long message that will be displayed in the toast. It is designed to test how the toast handles longer messages and whether it can accommodate them without overflowing or causing layout issues. The message can be customized as needed.',
                    type: ToastType.info,
                    position: ToastPosition.top,
                  ),
                  child: const Text('long message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
