template = require 'views/templates/reportgenerator'
debug = false

class ReportGenerator extends Backbone.View
    initialize: =>
        if debug then @debugReports()
        @region = 0 # Initially our custon "Entire World" collection

    debugReports: =>
        obi_questions = _EXPLORER_DATASET.groupings[0].entries[0].qs
        for country in _EXPLORER_DATASET.country
            for year in ['db_2006','db_2008','db_2010','db_2012']
                if year of country
                    score = @calculateScore country[year], obi_questions
                    expected = country[year].obi
                    if not (Math.round(expected*100) == Math.round(score*100))
                        console.warn 'Warning '+country.name+'.'+year+' failed data integrity test. Expected OBI='+expected+'; I calculated '+score
        console.log '[debug] Data integrity check complete.'

    ##################
    ## Public methods
    ##################
    setInitialState: =>
        @$el.find('#group-0').click()

    render: (target) =>
        renderData = 
            groupings0: _EXPLORER_DATASET.groupings.slice(0,3)
            groupings1: _EXPLORER_DATASET.groupings.slice(3,5)
            question: ( _EXPLORER_DATASET.question[x] for x of _EXPLORER_DATASET.question )
            country: _EXPLORER_DATASET.country
            regions: _EXPLORER_DATASET.regions
        # Write to DOM
        @$el.html template renderData
        target.empty().append @$el

        @$el.find('.group-toggler').bind 'mouseover', @_hoverGroupToggle
        @$el.find('.group-toggler').bind 'click', @_clickGroupToggle
        @$el.find('.region-toggler').bind 'click', @_clickRegionToggle
        @$el.find('.group-toggler').bind 'mouseout', (e) =>
            @$el.find('.toggle-box').removeClass 'hover'
        @$el.find('.toggle-box').bind 'click', @_clickBoxToggle
        #@$el.find('.toggle-box').bind 'mouseover', @_showQuestion
        #@$el.find('.toggle-box').bind 'mouseout', @_hideQuestion
        @$el.find('.nav a').bind 'click', @_expand_collapse
        @$el.find('.select-or-clear button').bind 'click', @_select_or_clear
        @$el.find('.toggle-box').tooltip
            placement: 'left'
            delay: 100
            animation: true
        @$el.find('#region-'+@region).addClass 'active'
        # Bind to the accordion
        @$el.find('#accordion2').on('show',=> @trigger('resizeStart'); $('.customize-link').html('&laquo; Hide options') )
        @$el.find('#accordion2').on('hide',=> @trigger('resizeStart'); $('.customize-link').html('Customize Report &raquo;') )
        # Debug:
        #@$el.find('.more-options').click()

    calculateScore: (db, questionSet, verbose=false) =>
        if questionSet.length==0 then return 0
        acc = 0
        count = 0
        for x in questionSet
            if db[x] >= 0
                acc += db[x]
                count++
        if (count==0) then return -1
        if verbose
            console.log 'result', acc,count, (acc/count), Math.round(acc/count), questionSet
        return acc / count 

    ##################
    ## Private methods
    ##################
    _updated: =>
        @questionSet = []
        el = $('.toggle-box.select')
        for e in (el or [])
            @questionSet.push parseInt $(e).attr('id').substr(7)
        # Inner function
        # Calculate dataset of countries and scores
        @dataset_unrounded = []
        for country in _EXPLORER_DATASET.country
            obj = 
                country: country.name
                alpha2: country.alpha2
            for year in [2006,2008,2010,2012]
                if not (('db_'+year) of country) then continue
                score = @calculateScore(country['db_'+year], @questionSet)
                obj[year] = score
            @dataset_unrounded.push obj
        @dataset = []
        for x in @dataset_unrounded
            obj = $.extend( {}, x )
            for year in [2006,2008,2010,2012]
                if not (year of obj) then continue
                obj[year] = Math.round(obj[year])
            @dataset.push obj
        @trigger('update', @dataset, @questionSet, @region, @dataset_unrounded)

    _select_or_clear: (e) =>
        @_setSubtitle()
        @$el.find('.group-toggler').removeClass 'active'
        el = $(e.delegateTarget)
        if el.hasClass 'select'
            $('.toggle-box').addClass 'select'
        else if el.hasClass 'clear'
            $('.toggle-box').removeClass 'select'
        @_updated()

    _expand_collapse: (e) =>
        e.preventDefault()
        inner = @$el.find('.inner')
        li = ($(e.delegateTarget)).parents('li')
        @$el.find('.nav li').removeClass 'active'
        li.addClass 'active'
        if (li.hasClass 'more-options')
            @trigger 'resizeStart'
            inner.find('> .more').show(200)
            inner.find('> .less').hide(200)
        else if (li.hasClass 'less-options')
            @trigger 'resizeStart'
            @$el.find('.inner .group-toggler:first').click()
            @$el.find('.inner .region-toggler:first').click()
            inner.find('> .more').hide(200)
            inner.find('> .less').show(200)
        return false

    _setSubtitle: (title='Custom Report') =>
        @$el.find('.subtitle').html(title)

    _hoverGroupToggle: (e) ->
        el = $(e.delegateTarget)
        group = el.attr('id')
        $('#toggle-boxes .'+group).addClass 'hover'

    _clickGroupToggle: (e) =>
        e.preventDefault()
        el = $(e.delegateTarget)
        group = el.attr('id')
        @$el.find('.group-toggler').removeClass 'active'
        el.addClass 'active'
        @_setSubtitle el.text()
        x = @$el.find('#toggle-boxes')
        x.find('.toggle-box').removeClass 'select'
        x.find(' .'+group).addClass 'select'
        @_updated()
        return false

    _clickRegionToggle: (e) =>
        e.preventDefault()
        el = $(e.delegateTarget)
        @region = parseInt el.attr('id').replace('region-','')
        @$el.find('.region-toggler').removeClass 'active'
        el.addClass 'active'
        @_updated()
        return false

    _clickBoxToggle: (e) =>
        e.preventDefault()
        el = $(e.delegateTarget)
        if el.hasClass 'select'
            el.removeClass 'select'
        else
            el.addClass 'select'
        @_setSubtitle()
        @$el.find('.group-toggler').removeClass 'active'
        @_updated()
        return false

module.exports = new ReportGenerator()
