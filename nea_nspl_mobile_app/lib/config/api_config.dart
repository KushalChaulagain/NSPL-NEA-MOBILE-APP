class ApiConfig {
  // Base URL for the mobile API
  static const String baseUrl = 'https://nspl-project.vercel.app/api/mobile';

  // Auth endpoints
  static const String login = '/auth/login';

  // Field agent endpoints
  static const String fieldAgents = '/field-agents';

  // Task endpoints
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/'; // + taskId
  static const String completeTask = '/tasks/'; // + taskId + '/complete'
}
