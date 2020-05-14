require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'byebug'
require_relative 'model.rb'

include Model
enable :sessions


# Display Landing Page
# 
get('/') do
    session[:attempt] = 0
    slim(:index)
end

# Displays Register Page
# 
get('/register') do
    slim(:"users/new")
end

# Creates a new account and redirects to '/login'
# 
# @param [String] email, users email 
# @param [String] password, users password
# @param [String] confirm, users password confirmation
# @param [String] name, users name
# 
# @see Model#userexist
# @see Model#createuser
post('/newaccount') do
    email = params[:email]
    password = params[:password]
    confirm = params[:passwordconf]
    name = params[:name]
    avatar = "img/default.png"
    if confirm != password
        session[:route] = "/register"
        session[:error] = "Passwords don't match."
        redirect('/error')
    end
    result = userexist(email)
    if result.empty? == false
        session[:error] = "Account does not exist."
        session[:route] = "/register"
        redirect('/error')
    end
    createuser(email, password, name, avatar)
    redirect('/login')
end

# Shows error messages. Uses session to show them.
# 
get('/error') do
    slim(:error)
end

# Shows the login page
# 
get('/login') do
    slim(:"users/login")
end

# Logs in an account and redirects to '/webshop'
# 
# @param [String] email, users email 
# @param [String] password, users password 
# 
# @see Model#userexist
# @see Model#login
post('/loginacc') do
    email = params[:email]
    password = params[:password]
    if userexist(email).empty?
        session[:error] = "That account does not exist."
        session[:route] = "/login"
        redirect('/error')
    end
    status = update_timeout_status(session[:timeout], session[:start_time], session[:time_left])
    check = status.is_a? Integer
    if check
        session[:time_left] = status
    else
        session[:timeout] = status
    end
    if session[:timeout]
        session[:error] = "You have attempted to login too many times. Try again in #{session[:time_left]} seconds"
        session[:route] = "/login"
        redirect("/error")
    end
    val = login(email, password)
    if val[0]
        session[:email] = val[1]
        session[:user_id] = val[2]
        redirect('/webshop')
    else
        session[:start_time] = Time.new.to_i
        atts_time = add_attempt(session[:attempt], session[:start_time])
        session[:timeout] = atts_time[0]
        session[:attempt] = atts_time[1]
        session[:error] = "The password/email is wrong."
        session[:route] = "/login"
        redirect('/error')
    end 
end

# Shows the upload page for avatars
# 
get('/upload') do
    if session[:user_id] == nil
        session[:error] = "You have to login to upload avatar"
        session[:route] = "/profile"
        redirect("/error")
    end
    slim(:"webshop/uploadavatar")
end

# Uploads the file and replaces avatar for user and redirects to '/profile'
# 
# @param [String] file, name of file uploaded
# 
# @see Model#fileupload
# @see Model#changeavatar
post('/uploaded') do
    if session[:user_id] == nil
        session[:error] = "You have to log in before you can use this feature."
        session[:route] = "/login"
        redirect("/error")
    end
    files = fileupload(params[:file])
    if files == false
        session[:error] = "You used the wrong file extension. Only .png, .jpg and .gif are allowed."
        session[:route] = "/uploadtest"
        redirect("/error")
    end
    target = files[:target]
    tempfile = files[:tempfile]
    slimroute = files[:slimroute]
    user_id = session[:user_id]
    File.open(target, 'wb') {|f| f.write tempfile.read }
    filesize = File.size(target)
    if File.size(target) > 2000000
        File.delete(target)
        session[:error] = "File is too big. Max 2MB."
        session[:route] = "/upload"
        redirect('/error')
    end
    changeavatar(user_id, slimroute)
    redirect('/profile')
end

# Shows the entire webshop
#  
# @see Model#info
get('/webshop') do
    info = getinfo(session[:user_id])
    if session[:user_id] != nil
        slim(:"webshop/index", locals: {allinfo: info[0], listings: info[1], categories: info[2], relationtable: info[3], catarr: info[4]})
    else
        session[:error] = "You have to login to see this site"
        session[:route] = "/login"
        redirect("/error")
    end
end

# Shows the listing creation page
# 
# @see Model#showcat
get('/createlisting') do
    if session[:user_id] == nil
        session[:error] = "You have to login to create listing"
        session[:route] = "/login"
        redirect("/error")
    end
    categories = showcat()
    slim(:"webshop/new", locals: {categories:categories})
end

# Creates a new listing and redirects to '/webshop'
# 
# @param [String] title, listing title 
# @param [String] desc, description of listing 
# @param [String] categoryselect, which category was chosen for listing 
# 
# @see Model#listcreate
post('/createdlisting') do
    if session[:user_id] == nil
        session[:error] = "You have to login before you can use this."
        session[:route] = "/login"
        redirect("/error")
    end
    title = params[:title]
    desc = params[:desc]
    category = params[:categoryselect]
    unless params[:file] &&
           (tempfile = params[:file][:tempfile]) &&
           (name = params[:file][:filename])
      @error = "No file selected"
      return redirect('/createlisting')
    end
    puts "Uploading file, original name #{name.inspect}"
    target = "public/img/#{name}"
    bild = "img/#{name}"
    File.open(target, 'wb') {|f| f.write tempfile.read }
    mes = listcreate(title, desc, bild, category, session[:user_id])
    if mes == false
        session[:error] = "Wrong category, choose another."
        session[:route] = "/createlisting"
        redirect("/error")
    end
    redirect('/webshop')
end

# Deletes a listing by user or admin and redirects to '/webshop'
# 
# @param [String] list_id, id of listing  
# 
# @see Model#user_info
# @see Model#deletepost
post("/webshop/:list_id/delete") do
    if session[:user_id] == nil
        session[:error] = "You have to login before using this."
        session[:route] = "/login"
        redirect("/error")
    end
    post_id = params[:list_id]
    list_user_info = user_info(session[:user_id], post_id)
    if list_user_info[1][0]["user_id"] == session[:user_id] || list_user_info[0][0]["admin"] == "1"
        deletepost(post_id)
    else
        session[:error] = "That is not your post or you are not an admin."
        session[:route] = "/webshop"
        redirect("/error")
    end
    redirect("/webshop")
end

# Shows the page where user can update their listing
# 
# @param [String] post_id, id of listing 
# 
# @see Model#user_info
# @see Model#showcat
get("/webshop/:list_id/update") do
    
    post_id = params[:list_id]
    list_user_info = user_info(session[:user_id], post_id)
    categories = showcat()
    if list_user_info[1][0]["user_id"] == session[:user_id]
        slim(:"webshop/edit", locals: {list_info: list_user_info[1][0], post_id: post_id, categories: categories})
    else
        session[:error] = "You are not the owner of this post."
        session[:route] = "/webshop"
        redirect("/error")
    end
end

# Updates the listing chosen and redirects '/webshop'
# 
# @param [String] post_id, id of listing 
# @param [String] title, listing title 
# @param [String] desc, description of listing 
# @param [String] categoryselect, which category was chosen for listing 
# @param [String] file, name of file uploaded
# 
# @see Model#updatelisting
post("/webshop/:list_id/updatedlisting") do
    if session[:user_id] == nil
        session[:error] = "You have to login before using this."
        session[:route] = "/login"
        redirect("/error")
    end
    post_id = params[:list_id]
    title = params[:title]
    desc = params[:desc]
    category = params[:categoryselect]
    unless params[:file] &&
           (tempfile = params[:file][:tempfile]) &&
           (name = params[:file][:filename])
      @error = "No file selected"
      return redirect("/webshop/#{post_id}/update")
    end
    puts "Uploading file, original name #{name.inspect}"
    target = "public/img/#{name}"
    bild = "img/#{name}"
    File.open(target, 'wb') {|f| f.write tempfile.read }
    boo = updatelisting(post_id, title, desc, category, bild)
    if boo == false
        session[:error] = "Wrong category, choose another."
        session[:route] = "/webshop/#{post_id}/update"
        redirect("/error")
    end
    redirect("/webshop")
end

# Shows the profile of logged in user
# 
# @see Model#profileinfo
get("/profile") do
    if session[:user_id] != nil
        profileinfo = profileinfo(session[:user_id])
        slim(:"users/show", locals: {profileinfo: profileinfo})
    else
        session[:error] = "You need to be logged in to see your profile!"
        session[:route] = "/login"
        redirect("/error")
    end
end

# Shows admin settings
# 
# @see Model#admin
get("/adminsettings") do
    users = admin(session[:user_id])
    if session[:user_id] != nil
        if users[0][0]["admin"] == "1"
            slim(:"users/adminsettings", locals: {users: users})
        else
            session[:error] = "You are not an admin."
            session[:route] = "/webshop"
            redirect("/error")
        end
    else
        session[:error] = "You are not logged in."
        session[:route] = "/login"
        redirect("/error")
    end
end

# Deletes a user by an admin
# 
# @param [String] id, id of user deleted
# 
# @see Model#user_info
# @see Model#deleteuser
post("/users/:id/deleteuser") do
    if session[:user_id] == nil
        session[:error] = "You have to login before using this."
        session[:route] = "/login"
        redirect("/error")
    end
    del_id = params[:id]
    user_info = userinfodelete(session[:user_id], del_id)
    if user_info[1][0]["admin"] == "1"
        session[:error] = "You can't delete an admin."
        session[:route] = "/adminsettings"
        redirect("/error")
    else
        if user_info[0][0]["admin"] == "1"
            deleteuser(del_id)
            redirect("/adminsettings")
        else
            session[:error] = "You are not an admin."
            session[:route] = "/webshop"
            redirect("/error")
        end
    end
end

# Logs out existing user
# 
post("/logout") do
    session.clear
    redirect("/login")
end