require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'byebug'
require 'capybara'
require_relative 'model.rb'

enable :sessions
db = SQLite3::Database.new("database.db")
db.results_as_hash = true

get('/') do
    slim(:index)
end

get('/register') do
    slim(:"users/register")
end

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

get('/error') do
    slim(:error)
end


get('/login') do
    slim(:"users/login")
end

post('/loginacc') do
    email = params[:email]
    password = params[:password]
    if userexist(email).empty?
        session[:error] = "That account does not exist."
        session[:route] = "/login"
        redirect('/error')
    end
    val = login(email, password)
    if val
        redirect('/webshop')
    else
        session[:error] = "The password/email is wrong."
        session[:route] = "/login"
        redirect('/error')
    end 
end

get('/upload') do
    slim(:"webshop/upload")
end

post('/uploaded') do
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


get('/webshop') do
    info = getinfo(session[:user_id])
    if session[:user_id] != nil
        slim(:"webshop/webshop", locals: {allinfo: info[0], listings: info[1], categories: info[2], relationtable: info[3], catarr: info[4]})
    else
        session[:error] = "You have to login to see this site"
        session[:route] = "/login"
        redirect("/error")
    end
end

get('/createlisting') do
    categories = showcat()
    slim(:"webshop/createlisting", locals: {categories:categories})
end

post('/createdlisting') do
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

post("/webshop/:list_id/delete") do
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

get("/webshop/:list_id/update") do
    post_id = params[:list_id]
    list_user_info = user_info(session[:user_id], post_id)
    categories = showcat()
    if list_user_info[1][0]["user_id"] == session[:user_id]
        slim(:"webshop/update", locals: {list_info: list_user_info[1][0], post_id: post_id, categories: categories})
    else
        session[:error] = "You are not the owner of this post."
        session[:route] = "/webshop"
        redirect("/error")
    end
end

post("/webshop/:list_id/updatedlisting") do
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

get("/profile") do
    if session[:user_id] != nil
        profileinfo = profileinfo(session[:user_id])
        slim(:"users/profile", locals: {profileinfo: profileinfo})
    else
        session[:error] = "You need to be logged in to see your profile!"
        session[:route] = "/login"
        redirect("/error")
    end
end

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

post("/users/:id/deleteuser") do
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

post("/logout") do
    session.clear
    redirect("/login")
end