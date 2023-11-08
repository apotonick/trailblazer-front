require_relative "config/environment"

module ::Guard
  # https://github.com/guard/guard/wiki/Create-a-guard
  class Torture < Plugin
  end
end

pages_config = ::Torture::Cms::DSL.(ViewsController::Pages)

controller = ViewsController.new()
req = ActionDispatch::Request.new 'HTTP_HOST' => 'example.com'
controller.instance_variable_set(:@_request, req)

puts "here comes full site compile"
pages, returned = ::Torture::Cms::Site.produce_versioned_pages(pages_config,
  controller: controller, # TODO: pass this to all cells.
)

file_to_page_map  = returned.fetch(:file_to_page_map)
book_headers        = returned[:book_headers]

guard :torture do
  pages = {"section/rails/cells.md.erb" => 99}

  # This runs the modified test
  watch /section\/(.*)/ do |m|
    # pp file_to_page_map

    book_name, version = file_to_page_map.fetch(m[0])
    puts %(Re-rendering #{book_name}/#{version} because #{m[0].inspect} changed...)


    book_options = pages_config.fetch(book_name)[:versions].fetch(version).fetch(:options)
    book_sections = pages_config.fetch(book_name)[:versions].fetch(version).fetch(:sections)

    if book_headers[book_name].versions_to_h2_headers[version]
      # only applies to docs with h2 headers, not landing page.
      book_headers[book_name].versions_to_h2_headers[version].items = [] # FIXME: they will be recomputed in {render_page}.
    end

    page, _ = ::Torture::Cms::Site.render_page(name: book_name, sections: book_sections, book_headers: book_headers, version: version, **book_options)

    page, _ = ::Torture::Cms::Site.render_final_page([book_name, version], book_headers: book_headers,  controller: controller, **page)
    page, _ = ::Torture::Cms::Site.produce_page(**page)
  end
  # # This calls the plugin with a new file name - which may not even exist
  # watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }

  # # This call the plugin with the 'test' parameter - see Guard::Minitest docs
  # # for information in how it finds/choose files in the given 'test' directory
  # watch(%r{^test/test_helper\.rb$})      { 'test' }
end
