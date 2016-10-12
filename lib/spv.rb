# The main interface class

module SPV

  class Processor

    # Adds a new version of the pages to the particular page ids
    #
    # @param app [String] an application namespace, used to recognize application
    # @param src [String] path to to a source document
    # @param sel [String] page selection expression
    # @param ids [Array]  assigned ids, if nil the ids will be generated automatically, obligatory to submit new version of the page.
    # The process will start in the background if worker is present.
    # Returns an object with pages description and ids associations
    # that can be easly converted to JSON
    def add(app, src, sel=nil, ids=nil)

    end

    def del(app, ids)

    end

  end
end
