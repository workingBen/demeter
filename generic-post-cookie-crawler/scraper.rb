require 'net/http'
require 'net/https'
require 'ruby-debug'

module GaTechScraper
  OUTPUT_FILE = "iu_emails.txt"
  OUTPUT_FILE_NAMES = "iu_names_count.txt"
  @counter = 0
  @query_counter = 0
  @name = nil
  @outfile = nil
  @names_count_file = nil

  def self.run
    initialize
    loop_names
  end

  def self.initialize
    @outfile = f = File.open(OUTPUT_FILE,  "a+")   
    @names_count_file = f = File.open(OUTPUT_FILE_NAMES,  "a+")   
  end

  def self.loop_names
    load 'names.rb'
    NAMES.each do |name|
      @name = name
      @query_counter += 1
      puts "PROCESSING NAME #{@query_counter}: #{name}"
      process_name(name)
    end
  end

	def self.process_name(name)
		url = URI.parse('http://people.iu.edu/index.cgi')
		http = Net::HTTP.new(url.host, url.port)
		#http.use_ssl = true

    response, data = http.post(url.path, "lastname=&exactness=starts&firstname=#{name}&status=Student&campus=Any&netid=&Search=Search&sid=08cbd580b748f997ccb8ef34dec9bd42", 
		  {
		    'cookie' => '__utma=21583523.759818744.1323479548.1323649891.1323723985.3; __utmc=21583523; __utmz=21583523.1323479548.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); sid=bfe2e7f1705f1d3f95fcdfdb68e6f632; __utmb=21583523.3.10.1323723985',
		    'referer'=> '	http://www.iu.edu/people/',
		    'user-agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:8.0.1) Gecko/20100101 Firefox/8.0.1'
		    })

		process_links_in_doc(response.body.to_s)
	end

  def self.process_links_in_doc(parsed_url)
    urls = []
    parsed_url.each_line do |x|
      link = x.match(/href="?user_string=(.)*">/)
      if link and link[0]
        link = 'http://people.iu.edu/index.cgi' + link[0].gsub('href="', '').gsub('">', '')
        urls << link
      end
    end
    puts urls.to_s
#debugger

    urls.each do |url|
      get_url(url)
    end
  end

  def self.get_url(path)
		url = URI.parse('http://www.gatech.edu/directories/')
		http = Net::HTTP.new(url.host, url.port)
    response, data = http.get(path) 

    find_emails_in_doc(response.body.to_s)
  end

  def self.find_emails_in_doc(parsed_url)
    student = parsed_url.match(/TITLE: <\/span>(.)*Student(.)*<\/p>/)
    return unless student and student[0]
    parsed_url.each_line do |x|
      email = x.match(/[a-z1-9_\-\.]*@[a-z\.]*gatech.edu/)
      if email 
        email = email[0]
        if !email.include?('webmaster') and !email.include?('comments@')
          @counter += 1
          puts "Saving Email #{@counter}: #{email}"
          @outfile << email + "\n"
        end
      end
    end
    @outfile.flush

    count = @counter - count_start
    names_count = "#{count}#{" "*(5-count.to_s.size)} #{@name}"
    @names_count_file << names_count + "\n"
    @names_count_file.flush
    puts names_count
  end

end
