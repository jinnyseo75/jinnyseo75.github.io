require 'sinatra'
require 'sinatra/reloader' if development?
require 'sqlite3'
require 'bcrypt'
require 'redcarpet'

# Database setup
def init_db
  @db = SQLite3::Database.new 'blog.db'
  @db.results_as_hash = true
  
  # Create posts table if it doesn't exist
  @db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS posts (
      id INTEGER PRIMARY KEY,
      title TEXT,
      content TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  SQL
end

before do
  init_db
end

# Markdown renderer setup
def markdown
  @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    highlight: true
  )
end

# Routes
get '/' do
  @page = (params[:page] || 1).to_i
  @posts_per_page = 5
  offset = (@page - 1) * @posts_per_page
  
  @posts = @db.execute(
    "SELECT * FROM posts ORDER BY created_at DESC LIMIT ? OFFSET ?",
    [@posts_per_page, offset]
  )
  
  erb :index
end

get '/posts' do
  @posts = @db.execute("SELECT * FROM posts ORDER BY created_at DESC")
  erb :posts
end

get '/posts/new' do
  erb :new_post
end

post '/posts' do
  if params[:title].strip.empty? || params[:content].strip.empty?
    status 400
    return "제목과 내용을 모두 입력해주세요."
  end

  @db.execute(
    "INSERT INTO posts (title, content) VALUES (?, ?)",
    [params[:title], params[:content]]
  )
  redirect '/'
end

get '/posts/:id' do
  @post = @db.execute(
    "SELECT * FROM posts WHERE id = ?", 
    [params[:id]]
  ).first
  
  halt 404, "포스트를 찾을 수 없습니다." unless @post
  
  @post['content'] = markdown.render(@post['content'])
  erb :show_post
end

get '/about' do
  erb :about
end

# Error handling
not_found do
  erb :not_found
end

error 400..510 do
  erb :error
end 