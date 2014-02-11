require_relative "Exposer.rb"
require_relative "ExposeAst.rb"
require "json"

# A serialisable class which is exposed in a library.
# Allows querying data of classes from other libraries, not parsed in the current operation.
#
class ClassData
	# Create a ClassData, given a short name and a parent, fully qualified path. 
	# [parsedClass] is optional, and should only be supplied if it was parsed in this library. 
	def initialize(name, parent, parsedClass=nil)
		@name = name
		@fullyExposed = false
		@parsedClass = parsedClass
		@parentClass = parent
	end

	attr_reader :name, :fullyExposed, :parsedClass, :parentClass

	# Set this class as fully exposed, a fully exposed
	# class can be used as both an input and output argument.
	def setFullyExposed()
		@fullyExposed = true
	end

	# The parent class is supplied on construction, and worked out when creating all 
	# class meta data (in the Meta Data Generator). The parent class is the first
	# inherited class which is also exposed.
	def hasParentClass
		return @parentClass != nil
	end

	# Serialise the ClassData to json, except the [@parsedClass].
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

	# Create a ClassData from json, with a nil [@parsedClass]
	def self.from_json(data)
		cls = ClassData.new(data[:name], data[:parent])
		if(not data.include?(:partial))
			cls.setFullyExposed()
		end
		return cls
	end
end

# ClassDataSet is a set of classes which are exposed in some library(s).
# The data sets can be restored from disk, and merged to represent multiple libraries classes.
class ClassDataSet
	# Create a class set from a hash of fully qualified path, to ClassData
	def initialize(classes = {})
		@classes = classes
		@fullClasses = @classes.select { |key, val| val.fullyExposed }
	end

	attr_reader :classes, :fullClasses

	# Merge this set with another set.
	def merge(other)
		@classes.merge!(other.classes)
		@fullClasses.merge!(other.fullClasses)
	end

	# Find the class data for [clsPath] in this set, or nil.
	def findClass(clsPath)
		return classes[clsPath]
	end

	# Is the class path passed fully exposed?
	def fullyExposed?(cls)
		return fullClasses.include?(cls)
	end

	# Is the class path passed partially exposed (ie contained at all in the set)?
	def partiallyExposed?(cls)
		return classes.include?(cls)
	end

	def fullClassCount
		return fullClasses.length
	end

	# Create a ClassDataSet from two arrays, of fully exposed
	# classes, and partially exposed classes
	def self.fromClasses(fullClasses, partialClasses)
		classes = {}

		# Iterate, find a good parent class, and create the ClassData...
		partialClasses.each do |cls|

			superClass = nil
	    cls.superClasses.each do |cls|
	    	# Parent classes must be public
	      if(cls[:accessSpecifier] == :public)
	        clsPath = "::#{cls[:type].name}"

	        # Parent classes only need to be partially exposed...
	        if(partialClasses.any?{ |cls| cls.fullyQualifiedName == clsPath})
	          superClass = clsPath
	          break
	        end
	      end
	    end

			classes[cls.fullyQualifiedName] = ClassData.new(cls.name, superClass, cls)
		end

		# Now iterate and set any partial classes which are full to be full.
		fullClasses.each do |cls|	
			obj = classes[cls.fullyQualifiedName]
			raise "Classes must also be partial classes #{cls.fullyQualifiedName}" unless obj

			obj.setFullyExposed()
		end

		return ClassDataSet.new(classes)
	end

	# Save this set into [dir], in json form
	def export(dir)
		File.open(dir + "/classes.json", 'w') do |file| 
			file.write(JSON.pretty_generate(@classes))
		end
	end

	# Load a set from [dir].
	def self.import(dir)
    classes = JSON.parse(File.open("#{dir}/classes.json", "r").read())

  	outClasses = {}
  	classes.each do |ary|
			outClasses[ary[0]] = ClassData.from_json(ary[1]) 
		end

		return ClassDataSet.new(outClasses)
	end
end
