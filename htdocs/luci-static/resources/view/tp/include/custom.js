'use strict';
'require form';
'require fs';
'require rpc';

var callRunningStatus = rpc.declare({
	object: 'luci.v2ray',
	method: 'runningStatus',
	params: [],
	expect: { '': { code: 1 } }
});

var callV2RayVersion = rpc.declare({
	object: 'luci.v2ray',
	method: 'v2rayVersion',
	params: [],
	expect: { '': { code: 1 } },
	filter: function(res) {
		return res.code ? '' : res.version;
	}
});

var MyTextValue = form.TextValue.extend({
	__name__: 'MYAPP.TextValue',
	filepath: null,
	isjson: false,
	required: false,

	cfgvalue: function(section_id) {
		if (!this.filepath)
			return this.super('cfgvalue', [section_id]);

		return L.resolveDefault(fs.read(this.filepath), '');
	},

	write: function(section_id, value) {
		if (!this.filepath)
			return this.super('write', [section_id, value]);

		var content = value.trim().replace(/\r\n/g, '\n') + '\n';
		return fs.write(this.filepath, content);
	},

	validate: function(section_id, value) {
		if (this.required && !value)
			return _('%s is required.').format(this.titleFn('title', section_id));

		if (this.isjson) {
			var parsed = null;
			try {
				parsed = JSON.parse(value);
			}
			catch (e) {
				parsed = null;
			}

			if (!parsed || typeof parsed !== 'object')
				return _('Invalid JSON content.');
		}

		return true;
	}
});

var MyRunningStatus = form.AbstractValue.extend({
	__name__: 'MYAPP.RunningStatus',

	fetchVersion: function(node) {
		L.resolveDefault(callV2RayVersion(), '').then(function(version) {
			L.dom.content(node, version ? _('Version: %s').format(version) : E('em', { style: 'color: red;' }, _('Unable to get core version.')));
		});
	},

	pollStatus: function(node) {
		var notRunning = E('em', { style: 'color: red;' }, _('Not Running'));
		var running = E('em', { style: 'color: green;' }, _('Running'));

		L.Poll.add(function() {
			L.resolveDefault(callRunningStatus(), { code: 0 }).then(function(status) {
				L.dom.content(node, status.code ? notRunning : running);
			});
		}, 5);
	},

	load: function() {},
	cfgvalue: function() {},

	render: function() {
		var statusNode = E('span', { style: 'margin-left: 5px' }, E('em', {}, _('Collecting data...')));
		var versionNode = E('span', {}, _('Getting...'));

		this.pollStatus(statusNode);
		this.fetchVersion(versionNode);

		return E('div', { class: 'cbi-value' }, [statusNode, ' / ', versionNode]);
	},

	remove: function() {},
	write: function() {}
});

return L.Class.extend({
	TextValue: MyTextValue,
	RunningStatus: MyRunningStatus
});
