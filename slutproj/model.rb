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
    db.execute("INSERT INTO users(email, password, name, avatar) VALUES (?,?,?,?)", [email, password_digest, name, avatar])
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


#FIX DIS
def listcreate(title, desc, bild, category)
    categories = db.execute("SELECT category, id FROM categories")
    arr = []
    print categories
    categories.each do |category|
        p category
        arr << category["category"]
    end
    if !arr.include?(category)
        p "bad"
        redirect("/bad")
    end
    db.execute("INSERT INTO listings(title, desc, bild, user_id) VALUES (?,?,?,?)", [title, desc, bild, session[:user_id]])
    db.execute("INSERT INTO listing_cate_rel(listing_id, category_id) VALUES (?,?)", [db.execute("SELECT list_id FROM listings ORDER BY list_id DESC LIMIT 1")[0]["list_id"], db.execute("SELECT id FROM categories WHERE category=?", category)[0]["id"]])
end