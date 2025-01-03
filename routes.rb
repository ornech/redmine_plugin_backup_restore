RedmineApp::Application.routes.draw do
  get 'backup_restore/index', to: 'backup_restore#index'
  post 'backup_restore/backup', to: 'backup_restore#backup'
  get 'backup_restore/download', to: 'backup_restore#download'
  post 'backup_restore/restore', to: 'backup_restore#restore'
  get 'backup_restore/configure', to: 'backup_restore#configure'
  post 'backup_restore/update_config', to: 'backup_restore#update_config'
end
