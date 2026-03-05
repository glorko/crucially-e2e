Nested flows | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskFlow Control and LogicNested flowsReuse test logic by calling subflows from parent flows with runFlow.As your test suite grows, you'll find that certain sequences of commands are repeated across multiple flows. Common examples include logging in, clearing app state, or navigating to a specific screen.Instead of duplicating these commands in every file, you can define them once in a separate flow and run them using the runFlow command. This approach, known as nesting flows, helps you adhere to the DRY (Don't Repeat Yourself) principle, making your tests easier to read, maintain, and optimize.Basic usageTo run a subflow, use the runFlow command followed by the path to the flow file.In this example, the login.yaml subflow handles the entire login process for the Wikipedia Android app, including launching the app and navigating the menu. The main flow profile_test.yaml runs this subflow to authenticate before performing other checks.tests/profile_test.yaml (The main flow)common/login.yaml (The subflow)CopyappId: org.wikipedia
---
- launchApp
- runFlow: ../common/login.yaml 
- assertVisible: "Explore"CopyappId: org.wikipedia
---
- tapOn:
    id: drawer_icon_menu
- tapOn: LOG IN / JOIN WIKIPEDIA
- tapOn: Username
- inputText: myUsername
- tapOn: Password
- inputText: myPassword
- tapOn: LOG INPassing argumentsYou can make your nested flows dynamic by passing arguments. This allows you to reuse the same logic with different data, such as logging in with different user roles.Use the env key to pass variables to the subflow. Inside the subflow, you can access these variables using the ${VAR_NAME} syntax.tests/profile_test.yaml (The main flow)common/login.yaml (The subflow)CopyappId: org.wikipedia
---
- launchApp
- runFlow:
    file: ../common/login.yaml
    env:
        USERNAME: "myUser"
        PASSWORD: "myPassword"
- assertVisible: "Explore"CopyappId: org.wikipedia
---
- tapOn:
    id: drawer_icon_menu
- tapOn: LOG IN / JOIN WIKIPEDIA
- tapOn: Username
- inputText: ${USERNAME}
- tapOn: Password
- inputText: ${PASSWORD}
- tapOn: LOG INConditional executionYou can optimize your test execution by running nested flows only when specific conditions are met.To learn more about conditional execution, access the Conditions page.Best practices for optimizationAdopting a nested flow strategy directly contributes to an optimized testing process.Keep flows atomicEach nested flow should perform a single, well-defined task. For example, have separate flows for login.yaml, logout.yaml, and onboarding.yaml. This granular approach allows you to mix and match flows to create complex test scenarios without unnecessary overhead.Organized directory structureMaintain a clean project structure by grouping reusable flows. A common pattern is to have a subflows/ or common/ directory separate from your main test cases.Setup and teardownUse nested flows for setup and teardown routines. By isolating these steps, you can quickly adjust the initial state for all tests by modifying a single file. For instance, if the login UI changes, you only need to update subflows/login.yaml, and all tests using it will automatically work.Next stepsCheck the runFlow command for technical details, or explore Conditions to add logic to your flows.PreviousHow to use SelectorsNextWait commandsLast updated 21 days agoBasic usagePassing argumentsBest practices for optimizationNext stepsCopy.
├── flows/
│   ├── e2e/
│   │   ├── checkout_flow.yaml
│   │   └── profile_flow.yaml
│   └── subflows/
│       ├── login.yaml
│       └── payment_setup.yaml
