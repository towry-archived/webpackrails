namespace :npm do
  desc "Run npm install"
  task :install do
    sh "npm install && npm --save install railshot-webpack-plugin" do |ok, res|
      fail "Error running npm install." unless ok
    end
  end

  desc "Clean npm node_modules"
  task :clean do
    sh "rm -rf ./node_modules" do |ok, res|
      fail "Error cleaning npm node_modules." unless ok
    end
  end

  namespace :install do
    desc "Run a clean npm install"
    task :clean => ['npm:clean', 'npm:install']
  end
end
