namespace :batchy do
  task :rename do
    $0 = 'Doing things .... xxxxx'
    puts $1
    sleep 60
  end

  task :check do
    puts Sys::ProcTable.fields
  end
end