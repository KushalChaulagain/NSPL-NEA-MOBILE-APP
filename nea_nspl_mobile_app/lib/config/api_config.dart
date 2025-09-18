class ApiConfig {
  // Base URL for the API - single source of truth
  static const String baseUrl = 'https://nspl-project.vercel.app/api';

  // Auth endpoints
  static const String login = '/mobile/auth/login';

  // Field agent endpoints
  static const String fieldAgents = '/mobile/field-agents';

  // Task endpoints
  static const String tasks = '/mobile/tasks';
  static const String taskDetail = '/mobile/tasks/'; // + taskId
  static const String completeTask = '/mobile/tasks/'; // + taskId + '/complete'

  // Mobile admin gallery endpoints (follows mobile API pattern)
  static const String galleryImages = '/mobile/admin/gallery/images';
  static const String attachmentUrl =
      '/mobile/attachments/'; // + imageId + '/url'
}
