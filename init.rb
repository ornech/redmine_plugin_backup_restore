require 'redmine'

Redmine::Plugin.register :backup_restore do
  name 'Backup Restore Plugin'
  author 'Jean-François ORNECH'
  description 'This plugin provides an interface to backup, download, and restore the Redmine database.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :admin_menu, :backup_restore, { controller: 'backup_restore', action: 'index' }, caption: 'Backup & Restore'
  # menu :admin_menu, :backup_restore_configure, { controller: 'backup_restore', action: 'configure' }, caption: 'Configure'
  settings default: { 'setting_name' => 'default_value' }, partial: 'settings/backup_restore_settings'

end
