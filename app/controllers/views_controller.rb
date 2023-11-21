class ViewsController < ApplicationController
  require "cells"
  require "cells/__erb__"
  require "torture/cms"


  module My
    module Cell
      def self.delegate_to_controller_helpers(target, *methods) # FIXME: move to cells gem
        helpers = Module.new do
          methods.each do |name|
            define_method name do |*args, **kws, &block|
              @options[:controller].helpers.send(name, *args, **kws, &block)
            end
          end
        end

        target.include(helpers)
      end


      # This is delibarately a PORO, and not a cell, to play with the "exec_context" concept.
      class Section # #Torture::Cms::Section
        include Torture::Cms::Helper::Header # needs {headers}
        include Torture::Cms::Helper::Code   # needs {extract}

        def initialize(controller:, **options)
          @options = options.merge(controller: controller)
        end

        def to_h
          {
            headers: @options[:headers]
          }
        end

        def code(marker=nil, **kws, &block)
          render_code(marker: marker, **kws, &block)
        end

        # 'data-toggle': toggle, 'data-tag': "##{target}"
        def code_tabs(marker_for_activity, operation_repository: false, **kws)
          if operation_repository # TODO: use this everywhere.
            operation_code_options = {root: "../trailblazer-operation/test/docs/autogenerated"}
            operation_file = @options[:file]
          else
            operation_code_options = {}
            operation_file = "autogenerated/operation_#{@options[:file]}"
          end

          tabs = [{title: "Activity", options_for_code: {marker: marker_for_activity}}, {title: "Operation", options_for_code: {marker: marker_for_activity, file: operation_file, **operation_code_options}}]

          render_code_tabs(**kws, tabs: tabs)
        end

        def tabs(tab_1_options, tab_2_options)
          render_code_tabs(tabs: [tab_1_options, tab_2_options])
        end

        def render_code_tabs(tabs:, **kws)
          colors =  %(data-show-color="bg-bg-purple-1" data-hide-color="bg-[#E4E4E4]")
          code_tag_class = @options[:code_attributes][:class] # DISCUSS: do we always get this? this should be {required :code_attributes} in the cell's exec_context.
          code_tag_class = code_tag_class.sub("rounded", "")
          code_tag_class = code_tag_class + "rounded-tr rounded-b"

          code_options = {
            code_tag_attributes: @options[:code_attributes].merge(class: code_tag_class)
          }

          tab_1_options = tabs[0]
          tab_2_options = tabs[1]

          return %(<div class="spacing-y-0">) +

          %(<div class="spacing-x-1 mb-[6px]">
            <a href="#" data-toggle="code-tab" data-type="code-tab-activity">
              <span class="font-semi-bold bg-bg-purple-1 p-2 rounded-t" data-show="code-tab-activity" data-hide="code-tab-operation" #{colors}>#{tab_1_options[:title]}</span>
            </a>
            <a href="#" data-toggle="code-tab" data-type="code-tab-operation">
              <span class="font-semi-bold bg-[#E4E4E4] p-2 rounded-t" data-show="code-tab-operation" data-hide="code-tab-activity" #{colors}>#{tab_2_options[:title]}</span>
            </a>
          </div>) +

          %(<div class="code-tab-activity code-tab-content">#{render_code(**kws, **tab_1_options[:options_for_code], **code_options, &tab_1_options[:block_for_code])}</div>) +
          %(<div class="code-tab-operation code-tab-content hidden">#{render_code(**kws, **tab_2_options[:options_for_code], **code_options, &tab_2_options[:block_for_code])}</div>) +

          %(</div>)
        end

        def api(*) # FIXME: implement

        end

            # = image_tag "info_icon.svg"
        def info(type: :info, &block)
          box(img: "info_icon.svg", bg: "bg-bg-purple-1/50", &block)
        end

        def warning(&block)
          box(img: "light_bulb_icon.svg", bg: "bg-bg-orange", &block)
        end

        def box(bg:, img:, &block) # TODO: use cell for this.
          kramdown_options  = @options.fetch(:kramdown_options)
          convert_method    = kramdown_options.fetch(:converter)

          icon_tag = @options[:controller].helpers.image_tag img
          html  = yield

          html = Kramdown::Document.new(html, kramdown_options).send(convert_method) # TODO: encapsulate that.

          %(
<div class="rounded flex p-4 gap-4 #{bg}">
  #{icon_tag}
  <div class="space-y-3">
    #{html}
  </div>
</div>)
        end

        GemVersions = {
          dsl: ["trailblazer-activity-dsl-linear", "https://github.com/trailblazer/trailblazer-activity-dsl-linear/tree/v"],
          "trailblazer-rails" => ["trailblazer-rails", "https://github.com/trailblazer/trailblazer-rails/tree/v"],
          "trailblazer-macro" => ["trailblazer-macro", "https://github.com/trailblazer/trailblazer-macro/tree/v"],

        }

        def gem_version(name, version=nil, feature: true, **)
          full_name, url = GemVersions.fetch(name)

          tooltip =
            if version
              %(This feature was introduced in #{full_name} v#{version}.)
            else
              %(This feature is implement in the #{full_name} gem.)
            end

          svg = %(<svg class="fill-grey mt-[2px]" xmlns="http://www.w3.org/2000/svg" height="1em" viewBox="0 0 512 512"><!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2023 Fonticons, Inc. --><path d="M168.5 72L256 165l87.5-93h-175zM383.9 99.1L311.5 176h129L383.9 99.1zm50 124.9H256 78.1L256 420.3 433.9 224zM71.5 176h129L128.1 99.1 71.5 176zm434.3 40.1l-232 256c-4.5 5-11 7.9-17.8 7.9s-13.2-2.9-17.8-7.9l-232-256c-7.7-8.5-8.3-21.2-1.5-30.4l112-152c4.5-6.1 11.7-9.8 19.3-9.8H376c7.6 0 14.8 3.6 19.3 9.8l112 152c6.8 9.2 6.1 21.9-1.5 30.4z"/></svg>)

          %(<span class="flex max-w-fit max-h-7 border border-grey uppercase text-grey text-xs pt-1 pb-1 pl-2 pr-2 pr-1 ml-4 rounded">
            #{svg}
            <a href="" class="ml-1" title="#{tooltip}">#{name} #{version}</a>
          </span>)
        end

        def capture(&block)
          block
        end

        My::Cell.delegate_to_controller_helpers(self, :image_tag)

        module ImageTag
          def image_tag(*args, **options)
            super(*args, **Cms::Config.tailwind.img, **options)
          end
        end

        include ImageTag

        module H
          class Render < Torture::Cms::Helper::Header::Render
            step :embed, before: :render_header # append {:embed} to {:display_title}.

            def embed(ctx, embed: nil, display_title:, **)
              return true unless embed

              ctx[:display_title] = display_title + embed
            end

            class H4 < Render
              step :render_breadcrumb, replace: :render_header

              def render_breadcrumb(ctx, header:, classes:, display_title:, parent_header:, **)
                ctx[:html] = %(<h4 id="#{header.id}" class="#{classes}">#{parent_header.title}
                  <span class="text-purple bg-lighter-purple p-2 rounded font-medium">#{display_title}</span>

                  </h4>)
              end
            end
          end

          H2_CLASSES = Cms::Config.tailwind.h2.fetch(:class)
          H3_CLASSES = Cms::Config.tailwind.h3.fetch(:class)
          H4_CLASSES = Cms::Config.tailwind.h4.fetch(:class)

          def h2(*args, render: Render, **options)
            super(*args, **options, render: render, classes: H2_CLASSES)
          end

          def h3(*args, render: Render, **options)
            super(*args, **options, render: render, classes: H3_CLASSES)
          end

          def h4(*args, render: Render::H4, **options)
            super(*args, **options, render: render, classes: H4_CLASSES)
          end
        end

        include H
      end
    end
  end

  module Application
    module Cell
      class Container
        def initialize(controller:, **options)
          @options = options.merge(controller: controller) # TODO: find way how to specify required kws.
        end

        My::Cell.delegate_to_controller_helpers(self, :csrf_meta_tags, :csp_meta_tag, :stylesheet_link_tag, :javascript_importmap_tags)

        def script_for_page_identifier
          %(<script>pageIdentifier = "#{@options.fetch(:page_identifier)}";</script>)
        end

        def to_h
          {}
        end
      end

      class Layout
        # TODO: abstract into cells-5.
        module Render
          def initialize(controller:, **options)
            @options = options.merge(controller: controller)
          end

          My::Cell.delegate_to_controller_helpers(self, :link_to, :image_tag) # navbar.erb

          def render(template)
            ::Cell.({template: template, exec_context: self}) # DISCUSS: does {render} always mean we want the same exec_context?
          end

          def to_h
            {}
          end
        end

        include Render

        def navbar_link_to(text, path, is: nil)
          classes = @options[:belongs_to] == is ? "underline decoration-[5px] decoration-purple underline-offset-[15px]" : ""

          link_to text, path, class: "font-medium text-base uppercase lg:normal-case lg:font-semibold #{classes} #{navbar_link_classes}"
        end

        private def navbar_link_classes
          ""
        end

        def navbar_logo
          "logo_blue_ruby.svg"
        end

        def navbar_options
          "bg-white sticky"
        end

        def navbar_div_options
          ""
        end
      end

      # This is delibarately a PORO, and not a cell, to play with the "exec_context" concept.
      class Section # #Torture::Cms::Section
        include Torture::Cms::Helper::Header # needs {headers}

        def initialize(controller:, **options)
          @options = options.merge(controller: controller)
        end

        def to_h
          {
            headers: @options[:headers]
          }
        end
      end
    end
  end

  # app/concept/application
  #                         cell/landing
  #                         cell/documentation
  #                         cell/documentation/toc_right.rb
  #                         cell/documentation/toc_right.erb



  module Documentation
    module Cell
      class TocRight
        def initialize(controller:, h2:, **options)
          @options = options.merge(controller: controller, h2: h2)
        end

        My::Cell.delegate_to_controller_helpers(self, :link_to)

        def h2
          @options[:h2]
        end

        def css_id
          "right-toc-#{@options[:h2].id}"
        end

        def to_h
          {}
        end
      end

      class Layout
        def link_to(text, url, **options)
          %(<a href="" class="#{options[:class]}">#{text}</a>)
        end

        def initialize(left_toc_html:, right_tocs_html:, version_options:)
          @options = {left_toc_html: left_toc_html, right_tocs_html: right_tocs_html, documentation_title: version_options[:title]||raise, version_options: version_options }
        end

        def to_h
          {}
        end

        def toc_left
          @options[:left_toc_html]
        end

        def tocs_right
          @options[:right_tocs_html]
        end

        def documentation_title
          @options[:documentation_title]
        end

        def version_badge
          version = @options[:version_options][:book_version][1]
          %(<span class="py-1 px-3 border border rounded border border-white text-white bg-purple">#{version}</span>)
        end
      end

      class TocLeft
        include Torture::Cms::Helper::Toc::Versioned

        class MyIterated < Torture::Cms::Helper::Toc::Versioned::Iterated
          include Torture::Cms::Helper::Toc::Versioned::Iterate

          My::Cell.delegate_to_controller_helpers(self, :link_to)

          def initialize(controller:, **options)
            super(**options)

            @options = {controller: controller}
          end

          def older_versions
            _, h1 = @item

            versions = h1.versions_to_h2_headers
            return false if versions.size <= 1

            _older_versions = versions.to_a[1..-1].collect do |version, h2|
              {version: version, target: h2.options[:target], h2: h2}
            end
          end
        end

        class MyIterateVersion
          def initialize(item:, expanded_version:, **)
            @version = item
            @expanded_version = expanded_version
          end

          def color_class
            if expanded?
              return "border border-white text-white bg-purple"
            end

            "hover:bg-purple hover:border-purple hover:text-white border border-grey text-grey"
          end

          def expanded?
            @expanded_version == version
          end

          def target
            @version[:target]
          end

          def version
            @version[:version]
          end
        end

        def initialize(level_1_headers:, controller:)

          @options = {controller: controller}

          super(level_1_headers: level_1_headers, iterate_context_class: MyIterated)
        end

        My::Cell.delegate_to_controller_helpers(self, :link_to)

        # def link_to(text, url, **options)
        #   %(<a href="#{url}" class="#{options[:class]}">#{text}</a>)
        # end

        def to_h
          {}
        end
      end
    end

    Flow = Cms::Flow.build(
      toc_left:     {template_file: "app/concepts/cell/documentation/toc_left.erb", context_class: Documentation::Cell::TocLeft,
        options_for_cell: ->(ctx, level_1_headers:, controller:, **) { {level_1_headers: level_1_headers, controller: controller} },
        Trailblazer::Activity::Railway.Out() => {:content => :left_toc_html}},

      page:         {template_file: "app/concepts/cell/documentation/documentation.erb", context_class: Documentation::Cell::Layout,
        options_for_cell: ->(ctx, left_toc_html:, right_tocs_html:, content:, **options) { {yield_block: content, left_toc_html: left_toc_html, right_tocs_html: right_tocs_html, version_options: options} }},

      # application:  {template_file: "app/concepts/cell/application/layout.erb", context_class: Application::Cell::Layout, options_for_cell: Cms::Flow.options_for_cell},
      application:  {template_file: "app/concepts/cell/application/layout.erb", context_class: Application::Cell::Layout, options_for_cell: ->(ctx, controller:, content:, belongs_to:, **) { {yield_block: content, controller: controller, belongs_to: belongs_to} }},
      html:         {template_file: "app/concepts/cell/application/container.erb", context_class: Application::Cell::Container, options_for_cell: Cms::Flow.options_for_cell}
    )

    class Render < Torture::Cms::Page::Render::WithToc
      step :render_right_tocs
      step Subprocess(Flow)

      def render_right_tocs(ctx, level_1_headers:, controller:, **)
        books, (book_name, version) = level_1_headers

        raise "wrong format" unless level_1_headers[1].is_a?(Array)

        h2_headers = books.fetch(book_name).versions_to_h2_headers.fetch(version).items

        context_class = Documentation::Cell::TocRight
        template = ::Cell::Erb::Template.new("app/concepts/cell/documentation/toc_right.erb")


        right_tocs =
          h2_headers.collect do |h2|
            cell_instance = context_class.new(h2: h2, controller: controller) # DISCUSS: what options to hand in here?

            result = ::Cell.({template: template, exec_context: cell_instance})

            result.to_s
          end

        ctx[:right_tocs_html] = right_tocs.join("\n")
      end
    end
  end

  module Landing
    module Cell
      class Layout < Application::Cell::Layout
        # include Application::Cell::Layout::Render
        def navbar_options
          ""
        end

        def navbar_div_options
          "max-w-[1440px]"
        end

        private def navbar_link_classes
          "text-white"
        end

        def navbar_logo
          "logo_white_ruby.svg"
        end

        My::Cell.delegate_to_controller_helpers(self, :asset_path)
      end
    end

    Flow = Cms::Flow.build(
      # page: {template_file: "app/concepts/cell/landing/landing.erb", context_class: Landing::Cell::Layout, options_for_cell: Cms::Flow.options_for_cell_without_content},
      html: {template_file: "app/concepts/cell/application/container.erb", context_class: Application::Cell::Container, options_for_cell: Cms::Flow.options_for_cell}
    )
  end

  module Pro
    class Cell
      include Application::Cell::Layout::Render
    end

    Flow = Cms::Flow.build(
      page:         {template_file: "app/concepts/cell/pro/pro.erb", context_class: Pro::Cell, options_for_cell: Cms::Flow.options_for_cell_without_content},
      application:  {template_file: "app/concepts/cell/application/layout.erb", context_class: Application::Cell::Layout, options_for_cell: Cms::Flow.options_for_cell},
      html:         {template_file: "app/concepts/cell/application/container.erb", context_class: Application::Cell::Container, options_for_cell: Cms::Flow.options_for_cell}
    )
  end

  Pages = {
    # top-level options, going to all books.
    render: Documentation::Render,
    kramdown_options: kramdown_options = {converter: "to_fuckyoukramdown"}, # use Kramdown::Torture parser from the torture-server gem.

    section_cell: My::Cell::Section,
    section_cell_options: {
      controller: self,
      pre_attributes: Cms::Config.tailwind.pre,
      code_attributes: Cms::Config.tailwind.code,
      kramdown_options: kramdown_options
    },

    page_identifier: "docs",
    belongs_to: :documentation,

    "trailblazer" => { # FIXME
      toc_title: "Trailblazer",
      "2.1" => {
        title: "Trailblazer",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/",
        target_file: "public/2.1/docs/trailblazer/index.html",
        target_url:  "/2.1/docs/trailblazer/index.html",

        "trailblazer/generic.md.erb"  => {snippet_dir: "../trailblazer-activity-dsl-linear/test/docs", snippet_file: "activity_test.rb"},
        "trailblazer/learn.md.erb"  => {snippet_dir: "../trailblazer-activity-dsl-linear/test/docs", snippet_file: "activity_test.rb"},
        "trailblazer/to_2.1.md.erb"   => {snippet_dir: "../trailblazer-activity-dsl-linear/test/docs", snippet_file: "activity_test.rb"},
        "developer/debugging.md.erb"  => {snippet_dir: "../trailblazer-developer/test/docs", snippet_file: "developer_test.rb"},
        "developer/graph.md.erb"      => {snippet_dir: "../trailblazer-developer/test/docs", snippet_file: "graph_test.rb"},
      }
    },


    "operation" => {
      toc_title: "Operation",
      "2.1" => {
        title: "Operation",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/activity",
        target_file: "public/2.1/docs/operation/index.html",
        target_url:  "/2.1/docs/operation/index.html",

        "overview.md.erb" => { snippet_file: "activity_basics_test.rb" },
        "mechanics.md.erb" => { snippet_file: "mechanics_test.rb",          snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "step_dsl.md.erb" => { snippet_file: "step_dsl_test.rb",          snippet_dir: "../trailblazer-operation/test/docs" },
        "dsl/step.md.erb" => { snippet_file: "mechanics_test.rb",          snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "dsl/sequence.md.erb" => { snippet_file: "sequence_options_test.rb",          snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "dsl/patching.md.erb" => { snippet_file: "patching_test.rb" },


        "dsl/api.md.erb" => { snippet_file: "basics_test.rb" },
        "wiring_api/api.md.erb" => { snippet_file: "wiring_api_test.rb", snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "wiring_api/magnetic_to.md.erb" => { snippet_file: "wiring_api_test.rb", snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "wiring_api/path.md.erb" => { snippet_file: "wiring_api_test.rb", snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "wiring_api/subprocess.md.erb" => { snippet_file: "subprocess_test.rb", snippet_dir: "../trailblazer-operation/test/docs/autogenerated" },
        "wiring_api/fast_track.md.erb" => { snippet_file: "fast_track_layout_test.rb", snippet_dir: "../trailblazer-activity-dsl-linear/test/docs" },

        "dsl/composable_variable_mapping.md.erb" => { snippet_file: "composable_variable_mapping_test.rb" },
        "dsl/macro.md.erb" => { snippet_file: "macro_test.rb" },
        "task_wrap.md.erb" => { snippet_file: "task_wrap_test.rb" },
        "internals.md.erb" => { snippet_file: "macro_test.rb" },
        "internals/introspect.md.erb" => { snippet_file: "introspect_test.rb" },
        "interfaces.md.erb" => { snippet_file: "activity_test.rb" },
        "internals/path_layout.md.erb" => { snippet_file: "path_layout_test.rb" },
        "internals/fast_track_layout.md.erb" => { snippet_file: "fast_track_layout_test.rb" },
        "class_dependencies.md.erb" => {snippet_dir: "../trailblazer-operation/test/docs", snippet_file: "class_dependencies_test.rb"},
        "troubleshooting.md.erb" => {section_dir: "section/developer", snippet_dir: "../trailblazer-developer/test/docs", snippet_file: "developer_test.rb" },
        # "kitchen_sink.md.erb" => { snippet_file: "____test.rb" },
      },
      "< 2.1.1" => {
        options_for_toc: {outdated: true, tooltip: "Deprecated activity docs: :input/:output, ..."},
        title: "Operation",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/activity",
        target_file: "public/2.1/docs/activity/deprecated/index.html",
        target_url: "/2.1/docs/activity/deprecated/index.html",

        "deprecated.md.erb" => { snippet_file: "variable_mapping_test.rb" },
        "dsl/variable_mapping.md.erb" => { snippet_file: "variable_mapping_test.rb" },
        "wiring_api/deprecated_path_helper.md.erb" => { snippet_file: "variable_mapping_test.rb" },
      },
    },

    "rails_integration" => { # FIXME
      toc_title: "Rails integration",
      "2.1" => {
        title: "Rails integration",
        snippet_dir: "../trailblazer-rails/test/dummy/app/controllers",
        section_dir: "section/rails",
        target_file: "public/2.1/docs/rails_integration/index.html",
        target_url:  "/2.1/docs/rails_integration/index.html",

        "controller.md.erb"     => {snippet_file: "songs_controller.rb"},
        "cells.md.erb"     => {snippet_file: "songs_controller.rb"},
        "reform.md.erb"     => {snippet_file: "songs_controller.rb"},
        "loader.md.erb"     => {snippet_file: "songs_controller.rb"},
      }
    },

    "test" => { # FIXME
      toc_title: "Test",
      "2.1" => {
        title: "Trailblazer Test",
        snippet_dir: "../trailblazer-test/test/docs",
        section_dir: "section/trailblazer/test",
        target_file: "public/2.1/docs/test/index.html",
        target_url:  "/2.1/docs/test/index.html",

        "overview.md.erb" => {snippet_file: "assertions/pass_fail_test.rb"},
        "assertions/pass_fail.md.erb" => {snippet_file: "assertions/pass_fail_test.rb"},
        "assertions/expose.md.erb" => {snippet_file: "assertions/expose_test.rb"},
        "helpers/callable.md.erb" => {snippet_file: "helpers/callable_test.rb"},
        "helpers/mocking.md.erb" => {snippet_file: "helpers/mocking_test.rb"},
        "rspec.md.erb" => {snippet_file: "helpers/mocking_test.rb"},
        "system.md.erb" => {snippet_file: "helpers/mocking_test.rb"},
      }
    },

    "macro" => {
      toc_title: "Macro",
      "2.1" => {
        title: "Macro",
        snippet_dir: "../trailblazer-macro/test/docs",
        section_dir: "section/macro",
        target_file: "public/2.1/docs/macro/index.html",
        target_url: "/2.1/docs/macro/index.html",

        "overview.md.erb"   => {snippet_file: "model_test.rb"},
        "nested/dynamic.md.erb"   => {snippet_file: "nested_static_test.rb"},
        "nested/auto_wire.md.erb"   => {snippet_file: "nested_static_test.rb"},
        "wrap.md.erb"   => {snippet_file: "wrap_test.rb"},
        "each.md.erb"   => {snippet_file: "each_test.rb"},
        "model_find.md.erb"   => {snippet_file: "model/find_test.rb"},
        "model.md.erb"   => {snippet_file: "model_test.rb"},
        "rescue.md.erb"   => {snippet_file: "rescue_test.rb"},
        "policy.md.erb"   => {snippet_file: "policy_test.rb"},
        "contract.md.erb" =>  {snippet_dir: "../trailblazer-macro-contract/test/docs", snippet_file: "contract_test.rb"},
      }
    },

    "workflow" => { # FIXME
      toc_title: "Workflow",
      "2.1" => {
        title: "Workflow/BPMN",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/workflow",
        target_file: "public/2.1/docs/workflow/index.html",
        target_url:  "/2.1/docs/workflow/index.html",

        "overview.md.erb" => { snippet_file: "activity_basics_test.rb" }
      }
    },

    "endpoint" => { # FIXME
      toc_title: "Endpoint",
      "2.1" => {
        title: "Endpoint",
        snippet_dir: "../trailblazer-endpoint/test/rails-app",
        section_dir: "section/endpoint",
        target_file: "public/2.1/docs/endpoint/index.html",
        target_url:  "/2.1/docs/endpoint/index.html",

        "overview.md.erb"      => {snippet_file: "basics_test.rb"},
        "api.md.erb"           => {snippet_file: "basics_test.rb"},
        "web.md.erb"           => {snippet_file: "basics_test.rb"},

      }
    },

    "internals" => { # FIXME
      toc_title: "Internals",
      "2.1" => {
        title: "Internals",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/internals",
        target_file: "public/2.1/docs/internals/index.html",
        target_url:  "/2.1/docs/internals/index.html",

        "overview.md.erb" => {snippet_file: "internals_test.rb"},
        "dsl.md.erb" => {snippet_file: "internals_test.rb"},
        "introspect.md.erb" => {snippet_file: "internals_test.rb"},
        "wiring_api.md.erb" => {snippet_file: "internals_test.rb"},
        "activity.md.erb"   => {snippet_dir: "../trailblazer-operation/test/docs", snippet_file: "option_test.rb"},
        "operation.md.erb"   => {snippet_dir: "../trailblazer-operation/test/docs", snippet_file: "option_test.rb"},
        "context.md.erb"  => {snippet_dir: "../trailblazer-operation/test/docs", snippet_file: "operation_test.rb"},
        "option.md.erb"   => {snippet_dir: "../trailblazer-option/test/docs", snippet_file: "option_test.rb"},
        "developer.md.erb"   => {snippet_dir: "../trailblazer-developer/test/docs", snippet_file: "debugger_test.rb"},
        "core.md.erb"   => {snippet_dir: "../trailblazer-activity/test/docs", snippet_file: "internals_test.rb"},
        "core/deprecate.md.erb"   => {snippet_dir: "../trailblazer-activity/test/docs", snippet_file: "internals_test.rb"},
      }
    },

    "reform" => { # FIXME
      toc_title: "Reform",
      "2.1" => {
        title: "Reform 2",
        snippet_dir: "../reform/test/docs",
        section_dir: "section/reform",
        target_file: "public/2.1/docs/reform/index.html",
        target_url:  "/2.1/docs/reform/index.html",

        "overview.md.erb"                       => {snippet_file: "validation_test.rb"},
        "api.md.erb"                            => {snippet_file: "validation_test.rb"},
        "options.md.erb"                        => {snippet_file: nil},
        "data_types.md.erb"                     => {snippet_file: nil},
        "populators.md.erb"                     => {snippet_file: nil},
        "prepopulators.md.erb"                  => {snippet_file: nil},
        "validation.md.erb"                     => {snippet_file: "validation_test.rb"},
        "rails.md.erb"                          => {snippet_file: nil},
        "upgrading_guide.md.erb"                => {snippet_file: nil},
      },
      "3.0" => {
        title: "Reform 3",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/reform-3",
        target_file: "public/2.1/docs/reform/3.0/index.html",
        target_url:  "/2.1/docs/reform/3.0/index.html",

        "overview.md.erb" => { snippet_file: "activity_basics_test.rb" },
        "internals.md.erb" => { snippet_file: "activity_basics_test.rb" },
      }
     },

    "cells" => { # FIXME
      toc_title: "Cells",
      "2.1" => {
        title: "Cells 4",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/cells",
        target_file: "public/2.1/docs/cells/index.html",
        target_url:  "/2.1/docs/cells/index.html",

        "overview.md.erb"                        => {snippet_file: "activity_basics_test.rb"},
        "getting_started.md.erb"                 => {snippet_file: "activity_basics_test.rb"},
        "api.md.erb"                             => {snippet_file: "activity_basics_test.rb"},
        "trailblazer.md.erb"                     => {snippet_file: "activity_basics_test.rb"},
        "testing.md.erb"                         => {snippet_file: "activity_basics_test.rb"},
        "render.md.erb"                          => {snippet_file: "activity_basics_test.rb"},
        "rails.md.erb"                           => {snippet_file: "activity_basics_test.rb"},
        "templates.md.erb"                       => {snippet_file: "activity_basics_test.rb"},
        "troubleshooting.md.erb"                 => {snippet_file: "activity_basics_test.rb"},
      },
      "5.0" => {
        title: "Cells 5",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/cells-5",
        target_file: "public/2.1/docs/cells/5.0/index.html",
        target_url:  "/2.1/docs/cells/5.0/index.html",

        "overview.md.erb" => { snippet_file: "activity_basics_test.rb" }
      },
    },

    "representable" => { # FIXME
      toc_title: "Representable",
      "2.1" => {
        title: "Representable",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/representable",
        target_file: "public/2.1/docs/representable/index.html",
        target_url:  "/2.1/docs/representable/index.html",

        "3.0/overview.md.erb"                 =>  {snippet_file: "activity_basics_test.rb"},
        "3.0/api.md.erb"                 =>  {snippet_file: "activity_basics_test.rb"},
        "3.0/function_api.md.erb"        =>  {snippet_file: "activity_basics_test.rb"},
        "3.0/xml.md.erb"                 =>  {snippet_file: "activity_basics_test.rb"},
        "3.0/yaml.md.erb"                =>  {snippet_file: "activity_basics_test.rb"},
        "debugging.md.erb"               =>  {snippet_file: "activity_basics_test.rb"},
        "upgrading_guide.md.erb"         =>  {snippet_file: "activity_basics_test.rb"},
      }
    },

    "disposable" => { # FIXME
      toc_title: "Disposable",
      "2.1" => {
        title: "Disposable",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/disposable",
        target_file: "public/2.1/docs/disposable/index.html",
        target_url:  "/2.1/docs/disposable/index.html",

        "api.md.erb"                        =>  {snippet_file: "activity_basics_test.rb"},
        "default.md.erb"                    =>  {snippet_file: "activity_basics_test.rb"},
        "callback.md.erb"                   =>  {snippet_file: "activity_basics_test.rb"},
      }
    },

    "roar" => { # FIXME
      toc_title: "Roar",
      "2.1" => {
        title: "Roar",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/roar",
        target_file: "public/2.1/docs/roar/index.html",
        target_url:  "/2.1/docs/roar/index.html",

        "index.md.erb" => { snippet_file: "activity_basics_test.rb" }
      }
    },

# TODO: add learn/tutorial page.
    "tutorials" => { # FIXME
      toc_title: "Tutorials",
      include_in_toc: false,
      "2.1" => {
        title: "Trailblazer",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/activity",
        target_file: "public/2.1/docs/tutorial/index.html",
        target_url:  "/2.1/docs/tutorial/index.html",

        # "overview.md.erb" => { snippet_file: "activity_basics_test.rb" }
      }
    },

    "pro_page" => {
      page_identifier: "landing",
      toc_title: "Trailblazer PRO",
      include_in_toc: false,
      "2.1" => {
        title: "Trailblazer PRO",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/page",
        target_file: "public/2.1/pro.html",
        target_url:  "/2.1/pro.html",
        render: Pro::Flow,

        section_cell_options: {
          controller: self,
        },
      }
    },

    "landing" => {
      toc_title: "Trailblazer",
      include_in_toc: false,
      "2.1" => {
        page_identifier: "landing",
        title: "Trailblazer",
        snippet_dir: "../trailblazer-activity-dsl-linear/test/docs",
        section_dir: "section/landing",
        target_file: "public/2.1/index.html",
        target_url:  "/2.1/index.html",
        render: Landing::Flow,

        section_cell: Landing::Cell::Layout,
        section_cell_options: {
          controller: self,
        },


        "../../app/concepts/cell/application/navbar.erb" => {snippet_file: ""},
        "hero_section.erb" => { snippet_file: "" },
        "video_section.erb" => { snippet_file: "" },
        "animations.erb" => { snippet_file: "" },
        "for_whom_section.erb" => { snippet_file: "" },
        "abstractions.erb" => { snippet_file: "" },
        "features_section.erb" => { snippet_file: "" },
        "testimonials_section.erb" => { snippet_file: "" },
        "learn_more_section.erb" => { snippet_file: "" },
        "../../app/concepts/cell/application/chat_with_us.erb" => { snippet_file: "" },
        "../../app/concepts/cell/application/footer.erb" => { snippet_file: "" },
      }
    },

  }

  def docs # TODO: remove me, this is only for development.
    pages = Torture::Cms::DSL.(Pages)

    pages, _ = Torture::Cms::Site.render_pages(pages,
      controller: self, # TODO: pass this to all cells.
      # page_identifier: "docs",
    )

    activity_content_html = pages[4].to_h["2.1"][:content]

    render html: activity_content_html.html_safe
  end

  def docs_deprecated
    pages = Torture::Cms::DSL.(Pages)

    pages, _ = Torture::Cms::Site.render_pages(pages,
      controller: self, # TODO: pass this to all cells.
      # page_identifier: "docs",
    )

    activity_content_html = pages[4].to_h["< 2.1.1"][:content]

    render html: activity_content_html.html_safe
  end

  def product
   pages = Torture::Cms::DSL.(Pages)

    pages, _ = Torture::Cms::Site.render_pages(pages,
      controller: self, # TODO: pass this to all cells.
      # page_identifier: "docs",
    )

    activity_content_html = pages[-2].to_h["2.1"][:content]

    render html: activity_content_html.html_safe
  end

  def landing
    pages = Torture::Cms::DSL.(Pages)

    # pp pages


    pages, _ = Torture::Cms::Site.render_pages(pages,
      controller: self, # TODO: pass this to all cells.
    )

    # raise pages.keys.inspect
    activity_content_html = pages[-1].to_h["2.1"][:content]

    render html: activity_content_html.html_safe
  end

  def about;end

  def blog;end
end
