// lib/data/jobs_data.dart
import '../models/job.dart';

class JobsData {
  static List<JobModel> jobs = [
    JobModel(
      id: 'j1',
      title: 'Développeur Flutter Mobile',
      company: 'Tech Innovation',
      location: 'Tunis',
      description: 'Développement d\'applications mobiles avec Flutter',
      requirements: ['flutter', 'dart', 'firebase', 'mobile', 'api'],
      salaryRange: '1200 - 1800 TND',
    ),
    JobModel(
      id: 'j2',
      title: 'Full Stack Developer',
      company: 'Digital Solutions',
      location: 'Remote',
      description: 'Développement web et mobile',
      requirements: ['react', 'node', 'javascript', 'api', 'git'],
      salaryRange: '1500 - 2200 TND',
    ),
    JobModel(
      id: 'j3',
      title: 'Mobile Developer',
      company: 'Startup TN',
      location: 'Tunis',
      description: 'Création d\'applications Android & iOS',
      requirements: ['flutter', 'dart', 'android', 'ios', 'firebase'],
      salaryRange: '900 - 1600 TND',
    ),
    JobModel(
      id: 'j4',
      title: 'Backend Developer',
      company: 'Data Systems',
      location: 'Sfax',
      description: 'Développement backend et APIs',
      requirements: ['python', 'sql', 'node', 'api', 'git'],
      salaryRange: '1300 - 2000 TND',
    ),
  ];
}