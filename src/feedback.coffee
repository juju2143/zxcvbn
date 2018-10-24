scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Utilisez quelques mots, évitez les phrases courantes"
      "Pas besoin de symboles, chiffres ou lettres majuscules"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Ajoutez un mot ou deux. Les mots peu communs sont meilleurs.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Les rangées de touches simples sont faciles à deviner'
        else
          'Les motifs de clavier simples sont faciles à deviner'
        warning: warning
        suggestions: [
          'Utilisez un motif de clavier plus long avec plus de virages'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Les répétitions tels que "aaa" sont faciles à deviner'
        else
          'Les répétitions tels que "abcabcabc" ne sont que légèrement plus difficiles à deviner que "abc"'
        warning: warning
        suggestions: [
          'Évitez les mots et les caractères répétés'
        ]

      when 'sequence'
        warning: 'Les séquences tels que "abc" ou "6543" sont faciles à deviner'
        suggestions: [
          'Évitez les séquences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Les années récentes sont faciles à deviner"
          suggestions: [
            'Évitez les années récentes'
            'Évitez les années qui vous sont associées'
          ]

      when 'date'
        warning: "Les dates sont souvent faciles à deviner"
        suggestions: [
          'Évitez les dates et les années qui vous sont associées'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'C\'est un mot de passe commun dans le top 10'
        else if match.rank <= 100
          'C\'est un mot de passe commun dans le top 100'
        else
          'C\'est un mot de passe très commun'
      else if match.guesses_log10 <= 4
        'C\'est similaire à un mot de passe couramment utilisé'
    else if match.dictionary_name == 'english_wikipedia' or match.dictionary_name == 'french_wikipedia'
      if is_sole_match
        'Un mot par lui-même est facile à deviner'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names', 'qc_surnames', 'qc_male_names', 'qc_female_names']
      if is_sole_match
        'Les noms et prénoms par eux-mêmes sont faciles à deviner'
      else
        'Les noms et prénoms communs sont faciles à deviner'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "La capitalisation n'aide pas beaucoup"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Tout en majuscule est presque aussi facile à deviner que tout en minuscule"

    if match.reversed and match.token.length >= 4
      suggestions.push "Les mots inversés ne sont pas beaucoup plus difficiles à deviner"
    if match.l33t
      suggestions.push "Des substitutions prévisibles tels que '@' au lieu de 'a' n'aident pas beaucoup"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
