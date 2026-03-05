Make HTTP requests | Flows | Maestro DocsMaestro Docs⌘CtrlkAskIntroductionMaestro StudioMaestro CLIMaestro CloudFlowsAPI ReferenceExamplesResourcesGitBook AssistantWorking...Thinking...Good morningI'm here to help you with the docs.What is this page about?What should I read next?Can you give an example?⌘CtrliAI Based on your contextSendMaestro DocsMaestro Flows overviewFlow Control and LogicFlow control and logic overviewHow to use SelectorsNested flowsWait commandsLoopsConditionsParameters and constantsSpecify and start devicesHooksTest in different localesPermissionsDetect MaestroJavaScriptJavaScript overviewRun and debug JavaScriptManage data and statesMake HTTP requestsGenerate synthetic dataWorkspace ManagementWorkspace management overviewProject configurationDesign your test architectureTest discovery and tagsSequential executionTest reports and artifactsRecord your FlowAI test analysisPowered by GitBookOn this pageAskJavaScriptMake HTTP requestsMake HTTP API calls from your flows to set up test data or verify backend state.Maestro includes a built-in JavaScript HTTP client that allows you to interact with external APIs directly from your test flows. This is particularly useful for setting up test data, authenticating users, or verifying backend state without navigating through the UI.Making RequestsThe Maestro HTTP client is a wrapper around okhttp3 and provides simple methods for common HTTP verbs.You can use the following shorthand methods for standard requests:http.get(url, config)http.post(url, config)http.put(url, config)http.delete(url, config)For other methods (like PATCH or OPTION), use the generic request function:Copyconst response = http.request('https://example.com', {
    method: "PATCH",
    body: JSON.stringify({ status: "active" })
});Working with JSONMaestro provides a global json() function to parse HTTP response bodies into JavaScript objects.For example, assume that https://api.example.com/user/1 returns the following JSON response:Copy{
  "id": 1,
  "email": "[email protected]",
  "profile": {
    "name": "Jane Doe",
    "age": 32
  }
}You can parse the response body and access fields directly:In this example, the user’s name is read from profile.name and assigned to output.username.Configuration OptionsWhen making a request, you can pass a configuration object to define headers, bodies, or form data.HeadersPass custom headers, such as authentication tokens or content types, using the headers property.Request BodyFor POST, PUT, or PATCH requests, provide the payload in the body parameter. Remember to stringify JSON objects.Multipart Form DataTo upload files or send multipart data, use the multipartForm parameter. When sending files, the following parameters are available:filePath: The path to the file. It is required for file uploads.mediaType: The MIME type of the file (optional).If both body and multipartForm are provided in one request, the body parameter will be ignored.The response objectEvery HTTP call returns a response object containing the following fields:Field NameTypeDescriptionokBooleantrue if the request was successful (status 200-299).statusNumberThe HTTP status code (e.g., 200, 404).bodyStringThe raw string body of the response.headersObjectHTTP response headers (multiple values are comma-separated).Usage exampleA common pattern is to use the API to seed test data before executing UI interactions. This ensures that the specific data you need is present in the environment without relying on manual UI setup steps, which are often slow and flaky.In this example, we create a new appointment via a POST request and then verify that it appears in the app.The following script sends a request to an appointments API and stores the appointmentTitle in the output object to be used by the main flow.Once the script has run, the stored values can be accessed from any subsequent step in the Flow:Next stepLearn how to generate synthetic test data to create dynamic, realistic data at runtime, making your tests more flexible, reusable, and less dependent on hard-coded values.PreviousManage data and statesNextGenerate synthetic dataLast updated 21 days agoMaking RequestsWorking with JSONConfiguration OptionsThe response objectUsage exampleNext stepCopy// script.js
const response = http.get('https://api.example.com/user/1');

// Parse the body and access fields directly
const userData = json(response.body);
output.username = userData.profile.name;Copyconst response = http.get('https://example.com', {
    headers: {
        'Authorization': 'Bearer ' + output.token,
        'Content-Type': 'application/json'
    }
});Copyconst response = http.post('https://example.com/login', {
    body: JSON.stringify({
        username: "test_user",
        password: "password123"
    })
});Copy// script.js
const response = http.post('https://example.com/myEndpoint', {
    multipartForm: {
      "uploadType": "import",
      "data": {
        "filePath": filePath,
        "mediaType": "text/csv"
      }
    },
})Copy// create_appointment.js
const response = http.post('https://my-api.com/v1/appointments', {
    body: JSON.stringify({ 
        title: "Maestro Health Check",
        date: "2026-02-10"
    }),
    headers: { 'Content-Type': 'application/json' }
});

const data = json(response.body);

// Store the title globally so the Flow can assert on it
output.appointmentTitle = data.title;
Copy# flow.yaml
appId: com.example.app
---
- launchApp
- runScript: create_appointment.js
- tapOn: "My Appointments"
# Assert that the data we just created via API is now visible in the UI
- assertVisible: ${output.appointmentTitle}
