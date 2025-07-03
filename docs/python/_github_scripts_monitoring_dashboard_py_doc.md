Help on module monitoring_dashboard:

NAME
    monitoring_dashboard

DESCRIPTION
    Jules Bot Monitoring Dashboard
    Real-time monitoring and performance analytics for the Jules Bot Review System

CLASSES
    builtins.object
        JulesBotMonitor

    class JulesBotMonitor(builtins.object)
     |  JulesBotMonitor(db_path=None)
     |
     |  Methods defined here:
     |
     |  __init__(self, db_path=None)
     |      Initialize the monitoring dashboard.
     |
     |  generate_dashboard_report(self, hours=24)
     |      Generate a comprehensive dashboard report.
     |
     |  get_performance_trends(self, metric_name, hours=24)
     |      Get performance trends for a specific metric.
     |
     |  get_quality_score_distribution(self, days=7)
     |      Get distribution of quality scores over time.
     |
     |  get_system_health_summary(self, hours=24)
     |      Get system health summary for the last N hours.
     |
     |  init_database(self)
     |      Initialize the metrics database.
     |
     |  log_performance_metric(self, metric_name, value, unit, tags=None)
     |      Log a performance metric.
     |
     |  log_quality_assessment(self, pr_number, quality_score, review_type, files_count, issues_count, approval_status)
     |      Log a quality assessment result.
     |
     |  log_system_health(self, component, status, response_time, details='')
     |      Log system health check result.
     |
     |  seed_sample_data(self)
     |      Seed database with sample data for demonstration.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    main()
        Main function to run the monitoring dashboard.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\monitoring_dashboard.py


