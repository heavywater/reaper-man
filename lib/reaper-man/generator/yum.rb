require "reaper-man"
require "xmlsimple"
require "time"

module ReaperMan
  class Generator
    # Generator methods for yum
    module Yum

      # Version flag mappings
      VERSION_FLAGS = {
        "2" => "LT",
        "4" => "GT",
        "8" => "EQ",
        "10" => "LE",
        "12" => "GE",
      }

      # Location of xmlns (though all are now defunct)
      XMLNS_MAP = {
        :repo => "http://linux.duke.edu/metadata/repo",
        :common => "http://linux.duke.edu/metadata/common",
        :rpm => "http://linux.duke.edu/metadata/rpm",
        :filelists => "http://linux.duke.edu/metadata/filelists",
        :other => "http://linux.duke.edu/metadata/other",
      }

      # Generate the repository
      def generate!
        generate_dists(package_config[:yum])
      end

      # Generate the repository dists
      #
      # @param pkg_hash [Hash] repository description
      # @return [TrueClass]
      def generate_dists(pkg_hash)
        pkg_hash.each do |origin_name, dists|
          dists.each do |dist_name, dist_args|
            dist_args[:components].each do |component_name, arches|
              packages = arches.values.flatten.compact.map(&:values).flatten.compact.map(&:values).flatten.compact
              p_file = primary_file(origin_name, dist_name, component_name, packages)
              f_file = filelist_file(origin_name, dist_name, component_name, packages)
              sign_file_if_setup do
                repomd_file(origin_name, dist_name, component_name,
                            :primary => p_file,
                            :filelists => f_file)
              end
            end
          end
        end
        true
      end

      # Sign file if configured for signing
      #
      # @yield block returning file path
      # @return [String] file path
      def sign_file_if_setup(opts = nil)
        path = yield
        if signer && options[:sign]
          signer.file(path, nil, opts)
        end
        path
      end

      # Create a primary file
      #
      # @param origin_name [String]
      # @param dist_name [String]
      # @param component_name [String]
      # @param packages [Hash]
      # @return [Array<String>] path to file, path to compressed file
      def primary_file(origin_name, dist_name, component_name, packages)
        content = {
          :metadata => {
            :@xmlns => XMLNS_MAP[:common],
            "@xmlns:rpm" => XMLNS_MAP[:rpm],
            :@packages => packages.size,
            :package => packages.map { |package|
              {
                :@type => "rpm",
                :name => package["NAME"],
                :arch => package["ARCH"],
                :version => {
                  :@epoch => package["EPOCHNUM"],
                  :@ver => package["VERSION"],
                  :@rel => package["RELEASE"].split(".").first,
                },
                :checksum => [
                  {
                    :@type => "sha",
                    :@pkgid => "YES",
                  },
                  package[:generated_sha],
                ],
                :summary => package["SUMMARY"],
                :description => [package["DESCRIPTION"]].flatten.compact.join(" "),
                :packager => package["PACKAGER"],
                :url => package["URL"],
                :time => {
                  :@file => Time.now.to_i,
                  :@build => package["BUILDTIME"],
                },
                :size => {
                  :@archive => package["ARCHIVESIZE"],
                  :@package => package[:generated_size],
                  :@installed => package["LONGSIZE"],
                },
                :location => package[:generated_path],
                :format => {
                  "rpm:license" => package["LICENSE"],
                  "rpm:vendor" => package["VENDOR"],
                  "rpm:group" => package["GROUP"],
                  "rpm:buildhost" => package["BUILDHOST"],
                  "rpm:header-range" => {
                    :@start => package[:generated_header][:start],
                    :@end => package[:generated_header][:end],
                  },
                  "rpm:provides" => {
                    "rpm:entry" => Array.new.tap { |entries|
                      pro_ver = package["PROVIDEVERSION"].dup
                      package["PROVIDENAME"].each_with_index do |p_name, p_idx|
                        item = {:@name => p_name}
                        if p_flag = VERSION_FLAGS[package["PROVIDEFLAGS"][p_idx]]
                          p_ver, p_rel = pro_ver.shift.split("-", 2)
                          item.merge!(:@flags => p_flag, :@ver => p_ver, :@rel => p_rel, :@epoch => package["EPOCHNUM"])
                        end
                        entries.push(item)
                      end
                    },
                  },
                  "rpm:requires" => {
                    "rpm:entry" => Array.new.tap { |entries|
                      req_ver = package["REQUIREVERSION"].dup
                      package["REQUIRENAME"].each_with_index do |r_name, r_idx|
                        item = {:@name => r_name}
                        if r_flag = VERSION_FLAGS[package["REQUIREFLAGS"][r_idx]]
                          r_ver, r_rel = req_ver.shift.split("-", 2)
                          item.merge!(:@flags => r_flag, :@ver => r_ver, :@rel => r_rel, :@epoch => package["EPOCHNUM"])
                        end
                        entries.push(item)
                      end
                    },
                  },
                },
              }
            },
          },
        }
        args = [origin_name, dist_name, component_name, "repodata", "primary.xml"]
        [
          create_file(*args) do |file|
            file.puts generate_xml(content)
          end,
          compress_file(*args),
        ]
      end

      # Create a filelist file
      #
      # @param origin_name [String]
      # @param dist_name [String]
      # @param component_name [String]
      # @param packages [Hash]
      # @return [Array<String>] path to file, path to compressed file
      def filelist_file(origin_name, dist_name, component_name, packages)
        content = {
          "filelists" => {
            :@xmlns => XMLNS_MAP[:filelists],
            :@packages => packages.size,
            :package => packages.map { |package|
              {
                :@pkgid => package[:generated_sha],
                :@name => package["NAME"],
                :@arch => package["ARCH"],
                :version => {
                  :@epoch => package["EPOCHNUM"],
                  :@ver => package["VERSION"],
                  :@rel => package["RELEASE"].split(".").first,
                },
                :file => (package["FILENAMES"] + package["DIRNAMES"]).map { |dir|
                  {:@type => "dir", :_content_ => dir}
                },
              }
            },
          },
        }
        args = [origin_name, dist_name, component_name, "repodata", "filelists.xml"]
        [
          create_file(*args) do |file|
            file.puts generate_xml(content)
          end,
          compress_file(*args),
        ]
      end

      # Create a repomd file
      #
      # @param origin_name [String]
      # @param dist_name [String]
      # @param component_name [String]
      # @param packages [Hash]
      # @return [String] path to file
      def repomd_file(origin_name, dist_name, component_name, files)
        content = {
          :repomd => {
            :@xmlns => XMLNS_MAP[:repo],
            :data => Hash.new.tap { |data|
              files.each do |f_name, f_paths|
                data[f_name] = {
                  :location => File.join("repodata", File.basename(f_paths.first)),
                  "open-checksum" => {
                    :@type => "sha",
                    :_content_ => checksum(File.open(f_paths.first), :sha1),
                  },
                  :checksum => {
                    :@type => "sha",
                    :_content_ => checksum(File.open(f_paths.last), :sha1),
                  },
                  :timestamp => File.mtime(f_paths.first).to_i,
                }
              end
            },
          },
        }
        args = [origin_name, dist_name, component_name, "repodata", "repomd.xml"]
        create_file(*args) do |file|
          file.puts generate_xml(content)
        end
      end

      # Generate XML document
      #
      # @param hash [Hash]
      # @return [String]
      def generate_xml(hash)
        XmlSimple.xml_out(hash,
                          "AttrPrefix" => true,
                          "KeepRoot" => true,
                          "ContentKey" => :_content_,
                          "XmlDeclaration" => '<?xml version="1.0" encoding="UTF-8" ?>')
      end
    end
  end
end
