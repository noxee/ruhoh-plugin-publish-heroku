require 'tmpdir'

# Usage: 
# add to ruhoh-site/plugins/publish/heroku.rb
# @param[opts] - CLI arguments
# @param[config] - config hash supplied from publish.yml or publish.json
#
# Example publish.json file:
# {
#	"heroku": {
#		"app": "blooming-savannah-7049",
#		"site-name": "My awesome blog"
#	}
# }
#
# $ cd ruhoh-site
# $ bundle exec ruhoh publish heroku

class Ruhoh
	class Publish::Heroku
		def run(opts={}, config={})
			check_for_config(config)			

			ruhoh = compile			
			
			app_name = config["app"] if config.has_key?("app")
			
			site_name = config["site-name"] if config.has_key?("site-name")

			config_publish_dir
			
			app_name = check_heroku_app(app_name)

			remote_exist = associate_remote?(app_name)	

			copy_compiled_site(ruhoh)
			
			run_bundler(remote_exist)

			commit_deploy_changes(site_name, app_name, remote_exist)

			perform_clean_up
		end

		def check_for_config(config)
			if config.nil?
				puts "No publish.(json/yml) config file found. Exiting..."
				exit
			end
		end

		def check_heroku_app(app_name)
			if app_name.to_s == ''
				puts "Creating new heroku app as no app name was provided."
								
				app_name = create_heroku_app
				
				puts "Created heroku app: #{ app_name }"
			elsif heroku_app_does_not_exist?(app_name)
				puts "No app was found matching the name '#{ app_name }'."

				create_app = get_response while create_app.nil?

				if create_app
					puts "Creating new heroku app..."
					app_name = create_heroku_app
					puts "Created heroku app: #{ app_name }"
				else
					puts "\nTerminating publish process as there will be no heroku app to publish to."
					exit
				end
			end

			app_name
		end

		def create_heroku_app
			`heroku create`[/Creating (.+)\.{3}/, 1]
		end

		def heroku_app_does_not_exist?(app_name)
			!system("heroku apps:info --app #{ app_name } > /dev/null 2>&1")
		end

		def compile
			ruhoh = Ruhoh.new
			ruhoh.env = 'production'
			ruhoh.setup_plugins

			config_overrides = set_configuration(ruhoh.config)
			ruhoh.config.merge!(config_overrides)

			ruhoh.config['compiled_path'] = File.join(Dir.tmpdir, 'compiled')
			ruhoh.compile
			ruhoh
		end

		def set_configuration(config)
			opts = {}
			opts['compile_as_root'] = true
			opts['base_path'] = "/"

			opts
		end

		def associate_remote?(app_name)
			# We need to initialize this as a git repo before
			# we can peform any other actions
			`git init`

			puts "Adding remote to git for heroku app."
			# create remote associate with heroku application
			`heroku git:remote -a #{ app_name } > /dev/null 2>&1`

			# update git's remote list to see if application already exists
			`git remote update> /dev/null 2>&1`

			remote_exist = `git show-ref`.include? 'remote'
			`git pull heroku master > /dev/null 2>&1` if remote_exist

			remote_exist
		end

		def config_publish_dir
			# If for some reason it wasn't actually cleaned up
			FileUtils.rm_rf("heroku_publish") if Dir.exist?("heroku_publish")	

			Dir.mkdir("heroku_publish")	
			Dir.chdir("heroku_publish")		
		end		

		def copy_compiled_site(ruhoh)
			config_location = File.join(File.expand_path(File.dirname(__FILE__)), 'configs/.')

			# Copy compiled website files to the public folder of the directory to be published
			FileUtils.cp_r(File.join(ruhoh.config["compiled_path"], '.'), './public')
			
			# Copy configuration files (Gemfile, config.ru) to the base of the directory to be published
			FileUtils.cp_r(config_location, '.')
		end

		def run_bundler(remote_exist)
			unless remote_exist			
				puts "Running 'bundle install'..."		
				Bundler.with_clean_env do
					puts "'bundle install' successful." if `bundle install`.include? "Your bundle is complete!"
				end				
			end
		end

		def commit_deploy_changes(site_name, app_name, remote_exist)
			# TODO: Add a better commit message
			`git add .`
			`git commit -m '#{ commit_message(site_name, remote_exist) }'`		
			
			puts "Deploying changes to #{ app_name}.herokuapp.com."
			
			if system('git push heroku master')
				puts "Deployment successful."
			else
				puts "Deployment failed for some reason."
			end
		end

		def commit_message(site_name, remote_exist)
			previous_commit_version = remote_exist ? last_commit_message('master')[/Version (\d+)/, 1].to_i : 0

			"#{ site_name } Version #{ previous_commit_version + 1 }"
		end

		def last_commit_message(branch)
      		`git show #{ branch } --summary --pretty=oneline --no-color`.lines.first
    	end

		def perform_clean_up			
			Dir.chdir("..")
			if Dir.exist?("heroku_publish")	
				puts "Deleting directory 'heroku_publish'."
				FileUtils.rm_rf("heroku_publish")
			end
		end

		def get_response
			print "Do you wish to create a new heroku app? [y/n]: "
			begin
				system("stty raw -echo")
				str = STDIN.getc.downcase
			ensure
				system("stty -raw echo")
			end
			if str == "y"
				return true
			elsif str == "n"
				return false
			else
				puts "\nInvalid input please enter either y/n."    
			end
		end
	end
end