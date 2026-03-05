Detect Maestro | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskFlow Control and LogicDetect MaestroDetect when your app is running under Maestro automation for test-specific behavior.There are times when your application needs to behave differently during a test. Whether you want to bypass a 2FA screen, disable analytics to avoid polluting production data, or point to a mock server, detecting Maestro within your app's code is a common requirement.Why detect Maestro?Detecting when your app is under test is a way to handle scenarios that are otherwise difficult to automate:Bypassing 2FA: Modify authentication flows to use fixed codes, avoiding the need for a physical SIM card or email inbox.Controlling Content Persistence: Keep short-lived messages (like temporary banners) on the screen longer so Maestro has enough time to detect and interact with them.Environment Switching: Automatically point your app to a mock server or a staging database to keep production data clean.Disabling Custom Animations: If your app uses specialized animations that aren't caught by the waitForAnimationToEnd, you can turn them off manually to prevent "ghost taps."Mobile (iOS and Android)The gold standard for detecting Maestro on mobile is using launchApp arguments. This approach is reliable, explicit, and works seamlessly in both local environments and Maestro Cloud.1Pass the argument in your FlowIn your Maestro Flow, use the arguments parameter within the launchApp command to send a custom flag.Copy- launchApp:
    appId: "com.example.app"
    arguments:
      isMaestro: "true"2Detect the argument in your codeYour application can then check for this flag during its initialization phase.Android (Kotlin/Java)iOS (Swift)React NativeFlutterCopyval isMaestro = intent.getStringExtra("isMaestro") == "true"
if (isMaestro) {
    // Disable analytics or use mock data
}Copyif ProcessInfo.processInfo.arguments.contains("isMaestro") {
    // Apply test-only configurations
}For React Native, you can use a library like react-native-launch-arguments to retrieve the parameters passed during startup.Copyimport { LaunchArguments } from 'react-native-launch-arguments';

if (LaunchArguments.value().isMaestro === "true") {
    // Apply test-only configurations
}For Flutter, the most straightforward approach is to use a package like flutter_launch_arguments to retrieve the parameters passed from Maestro without having to manually set up platform channels:Copyimport 'package:flutter_launch_arguments/flutter_launch_arguments.dart';

Future<void> getArguments() async {
  final fla = FlutterLaunchArguments();

  final foo = await fla.getString('foo');
  final isFooEnabled = await fla.getBool('isFooEnabled');
  final fooValue = await fla.getDouble('fooValue');
  final fooInt = await fla.getInt('fooInt');
}Checking for open ports (Deprecated)In the past, developers checked if ports 7001 (Android) or 22087 (iOS) were open. These were Maestro-specific ports that were used to detect Maestro.This method is now deprecated. It is unsupported in Maestro Cloud and may be removed in future updates. Maestro strongly recommends using the launchApp arguments approach.WebFor Web apps, Maestro simplifies detection by injecting a property directly into the global execution context.Maestro automatically defines window.maestro while a test is running. You can check for this property anywhere in your frontend code using window.maestro: Copyif (window.maestro) {
  console.log("Maestro test is running!");
}Related contentlaunchApp: Full technical reference for passing launch arguments.PreviousPermissionsNextJavaScript overviewLast updated 21 days agoWhy detect Maestro?Mobile (iOS and Android)Web
