require_relative "Exposer.rb"
require_relative "ExposeAST.rb"
require "json"

class ClassData
	def initialize(name, parent, parsedClass=nil)
		@name = name
		@fullyExposed = false
		@parsedClass = parsedClass
		@parentClass = parent
	end

	attr_reader :name, :fullyExposed, :parsedClass, :parentClass

	def setFullyExposed()
		@fullyExposed = true
	end

	def hasParentClass
		return @parentClass != nil
	end

	def to_json(opt)
		data = {
			:name => @name,
			:parent => @parentClass
		}
		if(!@fullyExposed)
			data[:partial] = true
		end
		return JSON.pretty_generate(data, opt)
	end

	def self.from_json(data)
		cls = ClassData.new(data[:name], data[:parent])
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

	def findClass(clsPath)
		return classes[clsPath]
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
			superClass = nil
	    cls.superClasses.each do |cls|
	      if(cls[:accessSpecifier] == :public)
	        clsPath = "::#{cls[:type].name}"
	        if(partialClasses.any?{ |cls| cls.fullyQualifiedName == clsPath})
	          superClass = clsPath
	          break
	        end
	      end
	    end

			classes[cls.fullyQualifiedName] = ClassData.new(cls.name, superClass, cls)
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
