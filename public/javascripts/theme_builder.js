
$j.maxZIndex = $j.fn.maxZIndex = function(opt) {
    /// <summary>
    /// Returns the max zOrder in the document (no parameter)
    /// Sets max zOrder by passing a non-zero number
    /// which gets added to the highest zOrder.
    /// </summary>    
    /// <param name="opt" type="object">
    /// inc: increment value, 
    /// group: selector for zIndex elements to find max for
    /// </param>
    /// <returns type="jQuery" />
    var def = { inc: 10, group: "*" };
    $j.extend(def, opt);    
    var zmax = 0;
    $j(def.group).each(function() {
        var cur = parseInt($j(this).css('z-index'));
        zmax = cur > zmax ? cur : zmax;
    });
    if (!this.jquery)
        return zmax;

    return this.each(function() {
        zmax += def.inc;
        $j(this).css("z-index", zmax);
    });
}

ThemeBuilder = {
  overBlockClassName: 'webiva-theme-builder-over-block',
  selectedBlockClassName: 'webiva-theme-builder-selected-block',
  blockLevelElements: 'div, h1, h2, h3, h4, ul, p, table',
  selectedBlock: null,
  zones: new Array(),

  disableEvents: function() {
    $j('*[onclick]').attr('onclick', '');
    $j('*[ondbclick]').attr('ondbclick', '');
    $j('*[onmouseover]').attr('onmouseover', '');
    $j('*[onmouseout]').attr('onmouseout', '');
    $j('*[onmousemove]').attr('onmousemove', '');
    $j('*[onmouseup]').attr('onmouseup', '');
    $j('*[onmousedown]').attr('onmousedown', '');
    $j('*[onkeyup]').attr('onkeyup', '');
    $j('*[onkeydown]').attr('onkeydown', '');
    $j('form').bind('submit', function() { return false; });
  },

  mouseOverBlock: function(event, block) {
    event.stopPropagation();

    if(ThemeBuilder.containsZone(block)) { return; }

    if(! ThemeBuilder.selectedBlock || $j(ThemeBuilder.selectedBlock).has(block).length == 0) {
      $j(block).addClass(ThemeBuilder.overBlockClassName);
    }
  },

  mouseOutBlock: function(event, block) {
    $j(block).removeClass(ThemeBuilder.overBlockClassName);
  },

  containsZone: function(block, exceptZone) {
    for(var i=0; i<ThemeBuilder.zones.length; i++) {
      if(! ThemeBuilder.zones[i]) { continue; }
      if(ThemeBuilder.zones[i] == exceptZone) { continue; }
      if($j(block).has(ThemeBuilder.zones[i].block).length > 0) {
        return true;
      }
    }

    return false;
  },

  selectBlock: function(event, block) {
    event.stopPropagation();

    if(ThemeBuilder.selectedBlock == block) {
      return;
    }

    if(ThemeBuilder.containsZone(block)) { return; }

    if(ThemeBuilder.selectedBlock) {
      var parent = ThemeBuilder.selectedBlock;
      if($j(parent).has(block).length > 0) { return; }

      var parents = $j(parent).parents(ThemeBuilder.blockLevelElements);
      if(parents.length <= 0) { return; }

      for(var i=0; i<parents.length; i++) {
        parent = parents[i];
        if($j(parent).has(block).length > 0) {
          break;
        }
      }

      if(ThemeBuilder.containsZone(parent)) { return; }

      ThemeBuilder.selectedBlock = parent;
    } else {
      ThemeBuilder.selectedBlock = block;
    }

    ThemeBuilder.resetBlockLevelEvents();
  },

  deselectBlock: function(event, block) {
    if(ThemeBuilder.selectedBlock != block) { return; }
    event.stopPropagation();

    ThemeBuilder.selectedBlock = null;

    ThemeBuilder.resetBlockLevelEvents();
  },

  canAddHoverEvent: function(block) {
    if($j(block).attr('id').match(/^webiva/) || $j(block).attr('class').match(/^webiva/)) {
      return false;
    }

    if(ThemeBuilder.selectedBlock) {
      if(ThemeBuilder.selectedBlock == block) {
        return false;
      }

      if($j(ThemeBuilder.selectedBlock).has(block).length > 0) {
        return false;
      }
    }

    if(ThemeBuilder.containsZone(block)) {
      return false;
    }

    return true;
  },

  resetBlockLevelEvents: function() {
    $j(ThemeBuilder.selectedBlock).unbind('hover');
    $j(ThemeBuilder.selectedBlock).unbind('click');

    $j(ThemeBuilder.blockLevelElements).each(
      function(index) {
        if(ThemeBuilder.canAddHoverEvent(this)) {
          $j(this).hover(function(e) { ThemeBuilder.mouseOverBlock(e,this); }, function(e) { ThemeBuilder.mouseOutBlock(e, this); });
          $j(this).click(function(e) { ThemeBuilder.selectBlock(e,this); return false; });
        }
      });

    if(ThemeBuilder.selectedBlock) {
      $j(ThemeBuilder.blockLevelElements).removeClass(ThemeBuilder.selectedBlockClassName);
      $j(ThemeBuilder.selectedBlock).addClass(ThemeBuilder.selectedBlockClassName);
      $j(ThemeBuilder.selectedBlock).unbind('hover');
      $j(ThemeBuilder.selectedBlock).unbind('click');
      $j(ThemeBuilder.selectedBlock).find(ThemeBuilder.blockLevelElements).unbind('hover');
      $j(ThemeBuilder.selectedBlock).find(ThemeBuilder.blockLevelElements).unbind('click');
      $j(ThemeBuilder.selectedBlock).click(function(e) { ThemeBuilder.deselectBlock(e,this); return false; });
      ThemeBuilder.showSelectZonePanel();
    } else {
      $j(ThemeBuilder.blockLevelElements).removeClass(ThemeBuilder.selectedBlockClassName);
      ThemeBuilder.hideSelectZonePanel();
    }

    ThemeBuilder.updateZonesList();
  },

  addZone: function() {
    if(! ThemeBuilder.selectedBlock) { return; }

    var index = ThemeBuilder.zones.length;
    $j(ThemeBuilder.selectedBlock).attr('zone', index);
    var name = "Zone " + (index+1);
    var id = $j(ThemeBuilder.selectedBlock).attr('id');
    if(id) {
      id = id.replace(/^ +/, '');
      id = id.replace(/ +/, '');
      id = id.replace(/[_\-]/, ' ');
      id = id.substr(0, 1).toUpperCase() + id.substr(1);
      name = id;
    }

    var zone = {block: ThemeBuilder.selectedBlock, name: name, index: index, editted: false};

    ThemeBuilder.zones.push(zone);

    ThemeBuilder.selectedBlock = null;

    ThemeBuilder.zonePanel(zone);

    ThemeBuilder.resetBlockLevelEvents();
  },

  changeZone: function(zone, block) {
    if(ThemeBuilder.containsZone(block, zone)) {
      return false;
    }

    var name = zone.name;
    if(! zone.editted) {
      var id = $j(block).attr('id');
      if(id) {
        id = id.replace(/^ +/, '');
        id = id.replace(/ +/, '');
        id = id.replace(/[_\-]/, ' ');
        id = id.substr(0, 1).toUpperCase() + id.substr(1);
        name = id;
      }
    }

    var newZone = {block: block, name: name, index: zone.index, editted: zone.editted};
    ThemeBuilder.zones[zone.index] = newZone;

    $j(zone.panel).remove();
    $j(zone.block).removeAttr('zone');
    $j(newZone.block).attr('zone', newZone.index);
    ThemeBuilder.selectedBlock = null;
    ThemeBuilder.zonePanel(newZone);
    ThemeBuilder.resetBlockLevelEvents();
    return true;
  },

  removeZone: function(zone) {
    $j(zone.panel).remove();
    $j(zone.block).removeAttr('zone');
    ThemeBuilder.zones[zone.index] = null;
    ThemeBuilder.resetBlockLevelEvents();
  },

  zonePanel: function(zone) {
    var parent = $j(zone.block).parent(ThemeBuilder.blockLevelElements);
    if(parent.length == 0) {
      parent = null;
    } else {
      parent = parent[0];
      if(ThemeBuilder.containsZone(parent, zone)) {
        parent = null;
      }
    }

    if(parent) {
      zone.parent = {block: parent, id: $j(parent).attr('id'), className: $j(parent).attr('class')};
    } else {
      zone.parent = null;
    }

    $j(zone.block).removeClass(ThemeBuilder.selectedBlockClassName);
    $j(zone.block).removeClass(ThemeBuilder.overBlockClassName);

    zone.id = $j(zone.block).attr('id');
    zone.className = $j(zone.block).attr('class');
    var w = $j(zone.block).outerWidth(true) - 2;
    var h = $j(zone.block).outerHeight(true) - 2;
    if(w > $j(document).width()) { w = $j(document).width(); }
    var offset = $j(zone.block).offset();
    var top = offset.top;
    var left = offset.left;
    var div = document.createElement('div');
    div.setAttribute('style', 'top:' + top + 'px; left:' + left + 'px; width:' + w + 'px; height:' + h + 'px;');
    div.setAttribute('class', 'webiva-theme-builder-zone-panel');
    var title = document.createElement('h5');
    if(h > 100) {
      title.setAttribute('style', 'padding-top: 15px;');
    } else {
      title.setAttribute('style', 'padding-top: 5px;');
    }
    var span = document.createElement('span')
    span.setAttribute('id', 'webiva-zone-' + zone.index);
    span.innerHTML = zone.name;
    $j(span).click(function(e) { ThemeBuilder.editZoneName(e, this, zone); });
    title.appendChild(span);
    var input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.setAttribute('value', zone.name);
    input.setAttribute('style', 'display:none;');
    input.setAttribute('id', 'webiva-zone-input-' + zone.index);
    $j(input).keypress(function(e) { ThemeBuilder.keypressZoneName(e, this, zone); });
    title.appendChild(input);

    span = document.createElement('span');
    span.setAttribute('class', 'tag');
    span.innerHTML = ThemeBuilder.tagDesc(zone).replace('<', '&lt;').replace('>', '&gt;');
    title.appendChild(span);

    var clear = document.createElement('a');
    clear.setAttribute('class', 'webiva-theme-builder-clear-zone');
    clear.href = '#';
    clear.innerHTML = '[x] remove';
    $j(clear).bind('click', function() { ThemeBuilder.removeZone(zone); return false; });
    title.appendChild(clear);

    div.appendChild(title);

    if(zone.parent) {
      var anchor = document.createElement('a');
      anchor.zone = zone;
      anchor.href = '#';
      anchor.innerHTML = 'Select container';
      anchor.title = ThemeBuilder.tagDesc(zone.parent);
      $j(anchor).bind('click', function() { ThemeBuilder.changeZone(zone, zone.parent.block); return false; });
      var container = document.createElement('div');
      container.setAttribute('class', 'webiva-theme-builder-select-container');
      container.appendChild(anchor);
      /*
      span = document.createElement('span');
      span.setAttribute('class', 'tag');
      span.innerHTML = ThemeBuilder.tagDesc(zone.parent).replace('<', '&lt;').replace('>', '&gt;');
      container.appendChild(span);
      */
      div.appendChild(container);
    }

    document.getElementById('webiva-theme-builder-panels').appendChild(div);
    $j(div).maxZIndex({inc: 1});
    zone.panel = div;
  },

  tagDesc: function(tag) {
    var desc = "<" + tag.block.tagName;
    if(tag.id) {
      desc += " id=\"" + tag.id + "\"";
    }

    if(tag.className) {
      var className = tag.className.replace('webiva-theme-builder-over-block', '').replace('webiva-theme-builder-selected-block', '').replace(/^\s+/, '').replace(/\s+$/, '');
      if(className != '') {
        desc += " class=\"" + className + "\"";
      }
    }
    desc += ">";
    return desc;
  },

  editZoneName: function(event, block, zone) {
    $j('#webiva-zone-' + zone.index).hide();
    $j('#webiva-zone-input-' + zone.index).show();

    setTimeout(function() {
      $j('#webiva-zone-input-' + zone.index).focus();
      $j('#webiva-zone-input-' + zone.index).bind('blur', function() {
        ThemeBuilder.keypressZoneName({keyCode: 13}, block, zone);
      });
    }, 10);
  },

  keypressZoneName: function(event, block, zone) {
    if(event.keyCode == 13) {
      var name = $j('#webiva-zone-input-' + zone.index).val();
      zone.name = name;
      zone.editted = true;
      $j('#webiva-zone-' + zone.index).text(name);
      $j('#webiva-zone-' + zone.index).show();
      $j('#webiva-zone-input-' + zone.index).hide();
      $j('#webiva-zone-input-' + zone.index).unbind('blur');
      ThemeBuilder.updateZonesList();
    } else if(event.keyCode == 27) {
      $j('#webiva-zone-' + zone.index).show();
      $j('#webiva-zone-input-' + zone.index).hide();
      $j('#webiva-zone-input-' + zone.index).unbind('blur');
      setTimeout(function() { block.value = zone.name; }, 10);
    }
  },

  showSelectZonePanel: function() {
    var panel = $j('#webiva-theme-builder-select-zone-panel').first();
    var block = ThemeBuilder.selectedBlock;
    var w = $j(block).outerWidth(true);
    if(w > $j(document).width()) { w = $j(document).width(); }
    var h = $j(block).outerHeight(true);
    var offset = $j(block).offset();

    var panelWidth = panel.outerWidth(true);
    var panelHeight = panel.outerHeight(true);

    var left = offset.left + (w-panelWidth) / 2;
    var top = offset.top + (h-panelHeight) / 2;
    if(left < 0) { left = 0; }
    if(top < 0) { top = 0; }

    $j('.webiva-theme-builder-select-zone-button').show();
    $j('.webiva-theme-builder-zone-tag').text(ThemeBuilder.tagDesc({block:block, id: $j(block).attr('id'), className: $j(block).attr('class')}));
    $j('.webiva-theme-builder-zone-name').text('Zone ' + (ThemeBuilder.zones.length+1));
    panel.css({top: top, left: left}).show();
    panel.maxZIndex({inc: 1});

    if(parent) {
      parent.$j('.webiva-theme-builder-select-zone-button').show();
      parent.$j('.webiva-theme-builder-zone-tag').text(ThemeBuilder.tagDesc({block:block, id: $j(block).attr('id'), className: $j(block).attr('class')}));
      parent.$j('.webiva-theme-builder-zone-name').text('Zone ' + (ThemeBuilder.zones.length+1));
    }
  },

  hideSelectZonePanel: function() {
    $j('.webiva-theme-builder-select-zone-button').hide();
    $j('#webiva-theme-builder-select-zone-panel').hide();
    $j('.webiva-theme-builder-zone-tag').text('');
    $j('.webiva-theme-builder-zone-name').text('Zone');

    if(parent) {
      parent.$j('.webiva-theme-builder-select-zone-button').hide();
      parent.$j('#webiva-theme-builder-select-zone-panel').hide();
      parent.$j('.webiva-theme-builder-zone-tag').text('');
      parent.$j('.webiva-theme-builder-zone-name').text('Zone');
    }
  },

  updateZonesList: function() {
    var listEle = document.getElementById('webiva-theme-builder-zones');
    if(! listEle && parent) {
      listEle = parent.document.getElementById('webiva-theme-builder-zones');
    }
    if(! listEle) { return; }

    listEle.innerHTML = '';

    for(var i=0; i<ThemeBuilder.zones.length; i++) {
      var zone = ThemeBuilder.zones[i];
      if(! zone) { continue; }
      var anchor = document.createElement('a');
      anchor.innerHTML = zone.name;
      anchor.title = ThemeBuilder.tagDesc(zone);
      var li = document.createElement('li');
      li.appendChild(anchor);
      listEle.appendChild(li);
    }
  },

  html: function(url) {
    for(var i=0; i<ThemeBuilder.zones.length; i++) {
      var zone = ThemeBuilder.zones[i];
      if(! zone) { continue; }

      $j(zone.block).html('<cms:zone name="' + zone.name + '"/>');
    }

    $j('#webiva-theme-builder').remove();

    return $j(document.body).html();
  }
};
