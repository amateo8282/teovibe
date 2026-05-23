class CreatePostsFts5 < ActiveRecord::Migration[8.1]
  def up
    # FTS5 가상 테이블 생성
    execute <<-SQL
      CREATE VIRTUAL TABLE IF NOT EXISTS posts_fts USING fts5(
        title, body, slug,
        content='posts',
        content_rowid='id'
      );
    SQL

    # 기존 데이터 동기화
    execute <<-SQL
      INSERT INTO posts_fts(rowid, title, body, slug)
      SELECT id, title, COALESCE(body, ''), COALESCE(slug, '')
      FROM posts;
    SQL

    # INSERT 트리거
    execute <<-SQL
      CREATE TRIGGER posts_fts_insert AFTER INSERT ON posts BEGIN
        INSERT INTO posts_fts(rowid, title, body, slug)
        VALUES (new.id, new.title, COALESCE(new.body, ''), COALESCE(new.slug, ''));
      END;
    SQL

    # UPDATE 트리거
    execute <<-SQL
      CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, body, slug)
        VALUES ('delete', old.id, old.title, COALESCE(old.body, ''), COALESCE(old.slug, ''));
        INSERT INTO posts_fts(rowid, title, body, slug)
        VALUES (new.id, new.title, COALESCE(new.body, ''), COALESCE(new.slug, ''));
      END;
    SQL

    # DELETE 트리거
    execute <<-SQL
      CREATE TRIGGER posts_fts_delete AFTER DELETE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, body, slug)
        VALUES ('delete', old.id, old.title, COALESCE(old.body, ''), COALESCE(old.slug, ''));
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS posts_fts_insert;"
    execute "DROP TRIGGER IF EXISTS posts_fts_update;"
    execute "DROP TRIGGER IF EXISTS posts_fts_delete;"
    execute "DROP TABLE IF EXISTS posts_fts;"
  end
end
