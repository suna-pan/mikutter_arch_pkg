# -*- coding: utf-8 -*-
require 'rss'

Plugin.create(:mikutter_arch_pkg) do
  settings('arch_pkg') do
    adjustment('更新間隔[sec]', :arch_pkg_get_intrval, 10, 3000)
    adjustment('表示間隔[sec]', :arch_pkg_view_interval, 1, 60)
    adjustment('表示件数' , :arch_pkg_count, 1, 100)
    boolean('i686', :arch_pkg_i686)
    boolean('x86_64', :arch_pkg_x86_64)
    boolean('any', :arch_pkg_any)
  end

  UserConfig[:arch_pkg_get_intrval]   ||= 300
  UserConfig[:arch_pkg_view_interval] ||= 15
  UserConfig[:arch_pkg_count]         ||= 20

  if (t = (UserConfig[:arch_pkg_view_interval] * UserConfig[:arch_pkg_count])) > UserConfig[:arch_pkg_get_intrval]
    UserConfig[:arch_pkg_get_intrval] = t
  end

  def update(items)
    Thread.new do
      items[0...UserConfig[:arch_pkg_count]].each do |item|
        next if !UserConfig[:arch_pkg_i686] && item.title =~ /i686$/
        next if !UserConfig[:arch_pkg_x86_64] && item.title =~ /x86_64$/
        next if !UserConfig[:arch_pkg_any] && item.title =~ /any$/
        statusbar  = ObjectSpace.each_object(Gtk::Statusbar).to_a.first
        context_id = statusbar.get_context_id('archpkgrss')
        statusbar.push(context_id, item.title)
        sleep UserConfig[:arch_pkg_view_interval]
        statusbar.pop(context_id)
        item.title
      end
    end
  end

  def get
    Reserver.new(UserConfig[:arch_pkg_get_intrval].to_i) do
      rss = RSS::Parser.parse('https://www.archlinux.org/feeds/packages/')
      update(rss.items)
      get
    end
  end
  
  on_boot do
    rss = RSS::Parser.parse('https://www.archlinux.org/feeds/packages/')
    update(rss.items)
    get
  end
end
