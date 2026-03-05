Hooks | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskFlow Control and LogicHooksLearn how to use onFlowStart and onFlowComplete hooks for setup and cleanup automation.In automated testing, you often need to perform specific setup or cleanup tasks for every test. Instead of manually adding a runFlow to the start or end of every file, Maestro provides Hooks.Hooks provide a configuration section to place setup and teardown logic, separate from the steps in the test. This ensures a consistent environment, reduces boilerplate code, and simplifies maintenance.Types of HooksMaestro supports two primary hooks defined in the configuration section (above the --- marker in your Flow file). These hooks apply every time you run the Flow:HookWhen it runsIdeal Use CaseonFlowStartBefore every individual Flow begins.Resetting app state, logging in, or handling dynamic permissions.onFlowCompleteAfter every individual Flow finishes (Pass or Fail).Clearing cookies, logging out, reporting custom metrics, or deleting test data.Here's how you could use these hooks in your flow.yaml:Copy# flow.yaml
appId: my.app
onFlowStart:
  - runFlow: setup.yaml
  - runScript: setup.js
  - <any other command>
onFlowComplete:
  - runFlow: teardown.yaml
  - runScript: teardown.js
  - <any other command>
---
- launchAppBest practicesSince hooks run for every single Flow, a slow hook will significantly increase your total suite execution time.Be careful not to call a Flow that itself triggers the same hook, causing an infinite loop.Use the when block within your hook sub-flow to perform actions only on specific platforms (e.g., clearing the iOS Keychain).Use onFlowComplete hook to ensure your app is in a "neutral" state for the next test, such as navigating back to the home screen, logging out, or deleting test data from your environment.Usage exampleLet's walk through how to set up setup and teardown logic so that every test in your workspace starts with an authenticated user.Step 1: Create your login subflowCreate a reusable file at subflows/login.yaml:Step 2: Register the hookOpen your flow.yaml file and add the hooks to the configuration section:Step 3: Run your testsNow, when you run your test using maestro test ., it will execute the login.yaml sequence before starting the logic in your specific test file.Dynamic hooksYou can pass environment variables into your hooks just like a standard runFlow. This is useful for switching roles (e.g., User vs. Admin) across your entire suite.Handling hook failuresIt is important to understand how Maestro behaves when a hook encounters an error. Maestro’s logic remains consistent with industry-standard testing frameworks like JUnit (@Before/@After) and XCTest (setUp/tearDown).If a hook fails, Maestro prioritizes test integrity and environment cleanup.ScenarioResult / BehavioronFlowStart failsThe entire Flow is immediately marked as Failed (🔴).The main body of the Flow execution is skipped. The onFlowComplete hook is still executed to ensure cleanup occurs.onFlowComplete failsThe Flow is marked as Failed (🔴), even if the main body of the test passed.Related contentNested flows: Understand the underlying runFlow command used by hooks.Sequential execution: Learn how hooks interact when running tests in a specific order.Parameters and constants: See how to manage variables within your hooks.PreviousSpecify and start devicesNextTest in different localesLast updated 21 days agoUsage exampleDynamic hooksHandling hook failuresCopy# subflows/login.yaml
- tapOn: "Username"
- inputText: "maestro_user"
- tapOn: "Login"Copy# flow.yaml
appId: com.example.app

onFlowStart:
  runFlow: subflows/login.yamlCopy# flow.yaml
appId: com.example.app

onFlowStart:
  runFlow:
    file: subflows/login.yaml
    env:
      ROLE: "admin"
