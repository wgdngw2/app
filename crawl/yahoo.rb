# -*- coding: utf-8 -*-
#http://www.yahoo.co.jp/にいって、ニュースの記事を一つづつスクショ。
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'uri'
require 'nokogiri'
require 'sqlite3'

Capybara.current_driver = :selenium
Capybara.app_host = "http://www.yahoo.co.jp/"
Capybara.default_max_wait_time = 20

module Crawler
  class LinkChecker
    include Capybara::DSL
    def initialize()
      visit('')
    end

    def find_links
      @links = []

            within(:xpath, '//*[@id="topicsboxbd"]') do #http://www.yahoo.co.jp/の範囲だけを検索
                all('a').each do |a|
                    u = a[:href]
                    next if u.nil? or u.empty?
                    @links << u

                    # 収集するリンクを10個までに抑える
                    break if @links.size >= 5
                end
            end

      @links.uniq!
      @links
    end

    def get_articles()
      base = URI.parse(Capybara.app_host)
      crawler = Crawler::LinkChecker.new
      links = crawler.find_links

      articles = []

      links.each do |link|
        begin
          title,url = crawler.get_title_url(link)
          articles.push({title: title, url: url})
        rescue
          next
        end
      end
      articles
    end

    def insert(articles)
      cur = File.expand_path(File.dirname(File.dirname(__FILE__)))
      cur = cur + "/../yahooapp/db/development.sqlite3"
      db = SQLite3::Database.new(cur)
      articles.each do |article|
        title = article[:title]
        url = article[:url]
        db.execute('insert into articles ("title" , "url", "created_at","updated_at" ) values (?,?,?,?)', "#{title}","#{url}",'2018-03-22 21:00:00','2018-03-22 21:00:00')
      end
    end
    def get_title_url(link)
      visit(link)
      doc = Nokogiri::HTML.parse(page.html)
            title =  doc.xpath('//*[@id="link"]').text
            url = doc.xpath('//*[@id="link"]').attribute('href').to_s
      [title,url]
    end

  end
end

crawler = Crawler::LinkChecker.new
articles = crawler.get_articles()
crawler.insert(articles)
