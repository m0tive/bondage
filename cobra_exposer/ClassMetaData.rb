require_relative "Exposer.rb"
require_relative "ExposeAST.rb"
require "json"

class ClassData
	def initialize(name, parsedClass=nil)
		@name = name
		@fullyExposed = false
		@parsedClass = parsedClass
	end

	attr_reader :name, :fullyExposed, :parsedClass

	def setFullyExposed()
		@fullyExposed = true
	end

	def to_json(opt)
		data = {
			:name => @name
		}
		if(!@fullyExposed)
			data[:partial] = true
		end
		return JSON.pretty_generate(data, opt)
	end

	def self.from_json(data)
		cls = ClassData.new(data[:name])
		if(not data.include?(:partial))
			cls.setFullyExposed()
		end
		return cls
	end
end

class MetaDataGenerator
	def initialize(classes = {})
		@classes = classes
		@fullClasses = @classes.select { |key, val| val.fullyExposed }
	end

	attr_reader :classes, :fullClasses

	def merge(other)
		@classes.merge!(other.classes)
		@fullClasses.merge!(other.fullClasses)
	end

	def fullyExposed?(cls)
		return fullClasses.include?(cls)
	end

	def partiallyExposed?(cls)
		return classes.include?(cls)
	end

	def self.fromClasses(fullClasses, partialClasses)
		classes = {}

		partialClasses.each do |cls|
			classes[cls.fullyQualifiedName] = ClassData.new(cls.name, cls)
		end

		fullClasses.each do |cls|	
			obj = classes[cls.fullyQualifiedName]
			raise "Classes must also be partial classes #{cls.fullyQualifiedName}" unless obj

			obj.setFullyExposed()
		end

		return MetaDataGenerator.new(classes)
	end

	def export(dir)
		File.open(dir + "/classes.json", 'w') do |file| 
			file.write(JSON.pretty_generate(@classes))
		end
	end

	def self.import(dir)
    classes = JSON.parse(File.open("#{dir}/classes.json", "r").read())

  	outClasses = {}
  	classes.each do |ary|
			outClasses[ary[0]] = ClassData.from_json(ary[1]) 
		end

		return MetaDataGenerator.new(outClasses)
	end
end
