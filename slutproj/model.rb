# Contains all functions that use database
#
module Model

db = SQLite3::Database.new("db/database.db")
db.results_as_hash = true

# A function for using "db" in db.execute functions
# 
# @return [String] containing database
def db() 
    fat = SQLite3::Database.new("db/database.db")    
    fat.results_as_hash = true
    return fat
end

# A function for using "db" in db.execute functions
# 
# @param [String] email, contains email information
# 
# @return [Hash] containing user_id
def userexist(email)
    return db.execute("SELECT user_id FROM users WHERE email=?", email)
end

# Creates a user from information
# 
# @param [String] email, contains email
# @param [String] password, contains hashed password
# @param [String] name, contains name
# @param [String] avatar, contains avatar
# 
# @return [Nil] 
def createuser(email, password, name, avatar)
    password_digest = BCrypt::Password.create(password)
    admin = "0"
    db.execute("INSERT INTO users(email, password, name, avatar, admin) VALUES (?,?,?,?,?)", [email, password_digest, name, avatar, admin])
end

# Function for checking if password is correct
# 
# @param [String] email, contains email 
# @param [String] password, contains password
# 
# @return [Boolean] true or nothing
def login(email, password)
    password_digest = db.execute("SELECT password FROM users WHERE email=?", email)
    if BCrypt::Password.new(password_digest[0][0]) == password
        user_id = db.execute("SELECT user_id FROM users WHERE email=?", email)[0][0]
        return [true, email, user_id]
    else
        return [false]
    end
end

# Changes avatar for user
# 
# @param [String] user_id, contains id of user 
# @param [String] slimroute, contains route to file 
# 
# @return [Nil]
def changeavatar(user_id, slimroute)
    db.execute("UPDATE users SET avatar=? WHERE user_id=?", slimroute, user_id)
end

# Gets all information about user and listings
# 
# @param [String] user_id, contains id of user 
# 
# @return [Array] containing all hashes of information
def getinfo(user_id)
    info = []
    info << db.execute("SELECT * FROM users WHERE user_id=?", user_id)[0]
    info << db.execute("SELECT name, avatar, listings.* FROM users INNER JOIN listings ON users.user_id = listings.user_id")
    info << db.execute("SELECT category FROM categories")
    info << db.execute("SELECT * FROM listing_cate_rel")
    categories = db.execute("SELECT category FROM categories")
    arr = []
    categories.each do |category|
        arr << category["category"]
    end
    info << arr
    return info
end

# Gets all categories
# 
# @return [Array] containing all categories
def showcat()
    return db.execute("SELECT category FROM categories")
end

# Creates a listing
# 
# @param [String] title, contains title
# @param [String] desc, contains description
# @param [String] bild, contains imagepath
# @param [String] category, contains category
# @param [String] user_id, contains user_id
# 
# @return [Boolean] if category wrong
def listcreate(title, desc, bild, category, user_id)
    categories = db.execute("SELECT category, id FROM categories")
    arr = []
    print categories
    categories.each do |category|
        p category
        arr << category["category"]
    end
    if !arr.include?(category)
        return false
    end
    db.execute("INSERT INTO listings(title, desc, bild, user_id) VALUES (?,?,?,?)", [title, desc, bild, user_id])
    db.execute("INSERT INTO listing_cate_rel(listing_id, category_id) VALUES (?,?)", [db.execute("SELECT list_id FROM listings ORDER BY list_id DESC LIMIT 1")[0]["list_id"], db.execute("SELECT id FROM categories WHERE category=?", category)[0]["id"]])
end

# Uploads a file to the server
# 
# @param [String] filename, contains File name 
# 
# @return [Hash] containing file information
def fileupload(filename)
    unless filename &&
        (tempfile = filename[:tempfile]) &&
        (name = filename[:filename])
    @error = "No file selected"
    return false
    end
    p filename
    fileextension = filename["filename"]
    if File.extname("#{fileextension}") == ".png" or File.extname("#{fileextension}") == ".jpg" or File.extname("#{fileextension}") == ".jpeg" or File.extname("#{fileextension}") == ".gif"
        puts "Uploading file, original name #{name.inspect}"
        target = "public/img/#{name}"
        slimroute = "img/#{name}"
        files = {target: target, slimroute: slimroute, tempfile: tempfile}
        return files
    else
        return false
    end
end

# Returns user info and listing info
# 
# @param [String] user_id, contains user_id
# @param [String] list_id, contains list_id
# 
# @return [Array] containing user info and listing info
def user_info(user_id, list_id)
    return [db.execute("SELECT * FROM users WHERE user_id=?", user_id), db.execute("SELECT * FROM listings WHERE list_id=?", list_id)]
end

# Deletes a post
# 
# @param [String] post_id, contains post_id 
# 
# @return [Nil]
def deletepost(post_id)
    db.execute("DELETE FROM listings WHERE list_id=?", post_id)
    db.execute("DELETE FROM listing_cate_rel WHERE listing_id=?", post_id)
end

# Updates a listing
# 
# @param [String] post_id, contains id of listing 
# @param [String] title, contains title
# @param [String] desc, contains description
# @param [String] category, contains category
# @param [String] bild, contains imagepath
# 
# @return [Bool] if category wrong
def updatelisting(post_id, title, desc, category, bild)
    categories = db.execute("SELECT category, id FROM categories")
    arr = []
    print categories
    categories.each do |category|
        p category
        arr << category["category"]
    end
    if !arr.include?(category)
        return false
    end
    p title
    p desc
    p category
    p bild
    p post_id
    db.execute("UPDATE listings SET title=?, desc=?, bild=? WHERE list_id=?", title, desc, bild, post_id)
    db.execute("UPDATE listing_cate_rel SET category_id=? WHERE listing_id=?", db.execute("SELECT id FROM categories WHERE category=?", category)[0]["id"], post_id)
end

# Gets profile info from database
# 
# @param [String] user_id, contains user_id 
# 
# @return [Array] containing profile information
def profileinfo(user_id)
    categories = db.execute("SELECT category FROM categories")
    arr = []
    categories.each do |category|
        arr << category["category"]
    end
    return [db.execute("SELECT * FROM users WHERE user_id=?", user_id), db.execute("SELECT * FROM listings WHERE user_id=?", user_id), db.execute("SELECT * FROM listing_cate_rel"), arr]
end

# Gets user and admin information
# 
# @param [String] user_id, contains user_id 
# 
# @return [Array] containing user and admin information
def admin(user_id)
    return [db.execute("SELECT * FROM users WHERE user_id=?", user_id), db.execute("SELECT * FROM users")]
end

# Gets information about a user who's about to be deleted 
# 
# @param [String] user_id, contains user_id
# @param [String] del_id, contains id of user deletion
# 
# @return [Array] containing user info
def userinfodelete(user_id, del_id)
    return [db.execute("SELECT * FROM users WHERE user_id=?", user_id), db.execute("SELECT * FROM users WHERE user_id=?", del_id)]
end

# Deletes a user from database
# 
# @param [String] del_id,contains id of user deletion 
# 
# @return [Nil]
def deleteuser(del_id)
    db.execute("DELETE FROM users WHERE user_id=?", del_id)
    db.execute("DELETE FROM listings WHERE user_id=?", del_id)
end

# Adds a login attempt to a counter and starts a timer if the counter exceeds a number
#
def add_attempt(attempt, start_time)
    attempt+= 1
    p "login attemps = #{attempt}"
    if attempt >= 5
        p "start time = #{start_time}"
        timeout = true
        attempt = 0
        return [timeout, attempt]
    end
    return[false, attempt]
end


# Updates the timeout status and time left of the timeout
#
def update_timeout_status(timeout, start_time, time_left)
    if timeout
        current_time = Time.new.to_i
        p "current time = #{current_time}"
        diff = current_time - start_time
        p "curr - start = #{diff}"
        time_out_length = 300
        if diff >= time_out_length
            timeout = false
            return timeout
        else
            time_left = time_out_length - diff
            return time_left
        end
    end
end

end