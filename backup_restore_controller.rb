class BackupRestoreController < ApplicationController
  before_action :require_admin

  def index
    @backups = Dir.glob('/bitnami/redmine/backups/*.sql')
    Rails.logger.info "Listing backups: #{@backups}"
  end

  def backup
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    backup_file = "/bitnami/redmine/backups/redmine_backup_#{timestamp}.sql"
    db_user = ENV['REDMINE_DATABASE_USER']
    db_password = ENV['REDMINE_DATABASE_PASSWORD']
    db_name = ENV['REDMINE_DATABASE_NAME']
    db_host = ENV['REDMINE_DATABASE_HOST']
    db_port = ENV['REDMINE_DATABASE_PORT_NUMBER']

    Rails.logger.info "Database user: #{db_user}"
    Rails.logger.info "Database password: #{db_password}"
    Rails.logger.info "Database name: #{db_name}"
    Rails.logger.info "Database host: #{db_host}"
    Rails.logger.info "Database port: #{db_port}"

    command = "mariadb-dump -u #{db_user} -p#{db_password} -h #{db_host} -P #{db_port} #{db_name} > #{backup_file}"
    Rails.logger.info "Executing backup command: #{command}"

    # Capture the output and error of the command
    output = `#{command} 2>&1`
    result = $?.success?

    if result
      flash[:notice] = "Backup created successfully: #{backup_file}"
      Rails.logger.info "Backup created successfully: #{backup_file}"
    else
      flash[:error] = "Failed to create backup: #{backup_file}"
      Rails.logger.error "Failed to create backup: #{backup_file}"
      Rails.logger.error "Command output: #{output}"
    end
    redirect_to action: 'index'
  end

  def download
    backup_file = params[:file].to_s.gsub(/[^0-9A-Za-z.\-_]/, '') # Sécurisation du paramètre
    backup_path = "/bitnami/redmine/backups/#{backup_file}"

    if File.exist?(backup_path)
      Rails.logger.info "Downloading backup file: #{backup_file}"
      send_file backup_path, filename: backup_file, type: 'application/sql', disposition: 'attachment'
    else
      Rails.logger.error "File not found: #{backup_path}"
      flash[:error] = "Backup file not found."
      redirect_to action: 'index'
    end
  end


  def restore
    backup_file = params[:file]
    db_user = ENV['REDMINE_DATABASE_USER']
    db_password = ENV['REDMINE_DATABASE_PASSWORD']
    db_name = ENV['REDMINE_DATABASE_NAME']
    db_host = ENV['REDMINE_DATABASE_HOST']
    db_port = ENV['REDMINE_DATABASE_PORT_NUMBER']

    Rails.logger.info "Database user: #{db_user}"
    Rails.logger.info "Database password: #{db_password}"
    Rails.logger.info "Database name: #{db_name}"
    Rails.logger.info "Database host: #{db_host}"
    Rails.logger.info "Database port: #{db_port}"

    command = "mysql -u #{db_user} -p#{db_password} -h #{db_host} -P #{db_port} #{db_name} < /bitnami/redmine/backups/#{backup_file}"
    Rails.logger.info "Executing restore command: #{command}"

    # Capture the output and error of the command
    output = `#{command} 2>&1`
    result = $?.success?

    if result
      flash[:notice] = "Backup restored successfully: #{backup_file}"
      Rails.logger.info "Backup restored successfully: #{backup_file}"
    else
      flash[:error] = "Failed to restore backup: #{backup_file}"
      Rails.logger.error "Failed to restore backup: #{backup_file}"
      Rails.logger.error "Command output: #{output}"
    end
    redirect_to action: 'index'
  end

  def configure
    @db_user = ENV['REDMINE_DATABASE_USER']
    @db_password = ENV['REDMINE_DATABASE_PASSWORD']
    @db_name = ENV['REDMINE_DATABASE_NAME']
    @db_host = ENV['REDMINE_DATABASE_HOST']
    @db_port = ENV['REDMINE_DATABASE_PORT_NUMBER']
  end

  def update_config
    ENV['REDMINE_DATABASE_USER'] = params[:db_user]
    ENV['REDMINE_DATABASE_PASSWORD'] = params[:db_password]
    ENV['REDMINE_DATABASE_NAME'] = params[:db_name]
    ENV['REDMINE_DATABASE_HOST'] = params[:db_host]
    ENV['REDMINE_DATABASE_PORT_NUMBER'] = params[:db_port]
    flash[:notice] = "Configuration updated successfully."
    redirect_to action: 'configure'
  end
end
