db = SQLite3::Database.new("database.db")
db.results_as_hash = true

def db()
    fat = SQLite3::Database.new("database.db")    
    fat.results_as_hash = true
    return fat
end

def userexist(email)
    return db.execute("SELECT user_id FROM users WHERE email=?", email)
end

def createuser(email, password, name, avatar)
    password_digest = BCrypt::Password.create(password)
    admin = "0"
    db.execute("INSERT INTO users(email, password, name, avatar, admin) VALUES (?,?,?,?,?)", [email, password_digest, name, avatar, admin])
end

def login(email, password)
    password_digest = db.execute("SELECT password FROM users WHERE email=?", email)
    if BCrypt::Password.new(password_digest[0][0]) == password
        session[:email] = email
        session[:user_id] = db.execute("SELECT user_id FROM users WHERE email=?", email)[0][0]
        return true
    end
end

def changeavatar(slimroute)
    db.execute("UPDATE users SET avatar=? WHERE user_id=#{session[:user_id]}", slimroute)
end

def getinfo()
    info = []
    info << db.execute("SELECT * FROM users WHERE user_id=?", session[:user_id])[0]
    info << db.execute("SELECT * FROM listings")
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

def showcat()
    return db.execute("SELECT category FROM categories")
end


def listcreate(title, desc, bild, category)
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
    db.execute("INSERT INTO listings(title, desc, bild, user_id) VALUES (?,?,?,?)", [title, desc, bild, session[:user_id]])
    db.execute("INSERT INTO listing_cate_rel(listing_id, category_id) VALUES (?,?)", [db.execute("SELECT list_id FROM listings ORDER BY list_id DESC LIMIT 1")[0]["list_id"], db.execute("SELECT id FROM categories WHERE category=?", category)[0]["id"]])
end

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

def user_info(user_id, list_id)
    return [db.execute("SELECT * FROM users WHERE user_id=?", user_id), db.execute("SELECT * FROM listings WHERE list_id=?", list_id)]
end

def deletepost(post_id)
    db.execute("DELETE FROM listings WHERE list_id=?", post_id)
end

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