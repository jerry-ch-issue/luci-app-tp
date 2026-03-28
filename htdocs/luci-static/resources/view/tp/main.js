'use strict';
'require view';
'require form';
'require fs';
'require ui';
'require tools.widgets as widgets';
'require view/tp/include/custom as custom';

return view.extend({
	handleServiceReload: function(ev) {
		return fs.exec('/etc/init.d/v2ray', ['reload'])
			.then(L.bind(function(btn, res) {
				if (res.code !== 0) {
					ui.addNotification(null, [
						E('p', _('Reload service failed with code %d').format(res.code)),
						res.stderr ? E('pre', {}, [res.stderr]) : ''
					]);
					L.raise('Error', 'Reload failed');
				}
			}, this, ev.target))
			.catch(function(err) {
				ui.addNotification(null, E('p', err.message));
			});
	},

	render: function() {
		var m, s, o;

		m = new form.Map('v2ray', _('tp'));

		s = m.section(form.NamedSection, 'main', 'v2ray', _('Global Settings'));
		s.anonymous = true;
		s.addremove = false;

		s.option(custom.RunningStatus, '_status');

		o = s.option(form.Flag, 'enabled', _('Enabled'));
		o.rmempty = false;

		o = s.option(form.Button, '_reload', _('Reload Service'));
		o.inputstyle = 'action reload';
		o.inputtitle = _('Reload');
		o.onclick = L.bind(this.handleServiceReload, this);

		o = s.option(form.Value, 'v2ray_file', _('Core file'));
		o.datatype = 'file';
		o.placeholder = '/usr/bin/v2ray';
		o.rmempty = false;

		o = s.option(form.Value, 'config_file', _('Config file'));
		o.datatype = 'file';
		o.placeholder = '/etc/v2ray/config.json';
		o.rmempty = false;

		s = m.section(form.NamedSection, 'main_transparent_proxy', 'transparent_proxy', _('Transparent Proxy'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Value, 'redirect_port', _('Redirect port'));
		o.datatype = 'port';
		o.rmempty = false;

		o = s.option(widgets.NetworkSelect, 'lan_ifaces', _('LAN interfaces'));
		o.multiple = true;
		o.nocreate = true;
		o.filter = function(section_id, value) {
			return value.indexOf('wan') < 0;
		};
		o.rmempty = false;

		o = s.option(form.Flag, 'use_tproxy', _('Use TProxy'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.Flag, 'ipv6_tproxy', _('Proxy IPv6'));
		o.default = '1';

		o = s.option(form.Flag, 'redirect_udp', _('Redirect UDP'));
		o.default = '1';

		o = s.option(form.ListValue, 'proxy_mode', _('Proxy mode'));
		o.value('gfwlist_proxy', _('GFWList Proxy'));
		o.default = 'gfwlist_proxy';
		o.rmempty = false;

		o = s.option(form.DummyValue, '_gfw_list', _('GFWList'));
		o.cfgvalue = function() {
			return '/etc/v2ray/gfwlist.txt';
		};

		o = s.option(custom.TextValue, '_proxy_list', _('Extra proxy list'));
		o.wrap = 'off';
		o.rows = 5;
		o.datatype = 'string';
		o.filepath = '/etc/v2ray/proxylist.txt';

		o = s.option(custom.TextValue, '_direct_list', _('Extra direct list'));
		o.wrap = 'off';
		o.rows = 5;
		o.datatype = 'string';
		o.filepath = '/etc/v2ray/directlist.txt';

		o = s.option(form.Value, 'proxy_list_dns', _('Proxy list DNS'));
		o.placeholder = '1.1.1.1#53';

		o = s.option(form.Value, 'direct_list_dns', _('Direct list DNS'));
		o.placeholder = '223.5.5.5#53';

		o = s.option(custom.TextValue, '_src_direct_list', _('Local devices direct outbound list'));
		o.wrap = 'off';
		o.rows = 3;
		o.datatype = 'string';
		o.filepath = '/etc/v2ray/srcdirectlist.txt';

		return m.render();
	}
});
