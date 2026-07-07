import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: reviews, error } = await supabase
      .from('service_reviews')
      .select('stars, tags, comment, created_at')
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) throw error
    if (!reviews || reviews.length === 0) {
      return new Response(JSON.stringify({ error: 'No reviews found' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const reviewsText = reviews
      .map((r: any, i: number) => {
        const tags = r.tags?.join(', ') || 'none'
        const comment = r.comment?.trim() || 'No comment'
        return `Review ${i + 1}: ${r.stars}/5 stars. Tags: ${tags}. Comment: "${comment}"`
      })
      .join('\n')

    const groqRes = await fetch(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${Deno.env.get('GROQ_API_KEY')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'llama3-8b-8192',
          messages: [
            {
              role: 'system',
              content:
                'You are a professional service quality analyst for a Malaysian water and electricity utility company. Analyze repair service reviews. Always respond with valid JSON in this exact format: {"summary": "2-3 sentence overall assessment", "pros": ["pro 1", "pro 2", "pro 3"], "cons": ["con 1", "con 2"]}. Keep each pro/con under 5 words.',
            },
            {
              role: 'user',
              content: `Analyze these ${reviews.length} repair service reviews from mySumber customers:\n\n${reviewsText}\n\nProvide a balanced assessment focusing on repair quality and customer experience.`,
            },
          ],
          response_format: { type: 'json_object' },
          max_tokens: 512,
          temperature: 0.3,
        }),
      },
    )

    if (!groqRes.ok) {
      const errBody = await groqRes.text()
      throw new Error(`Groq API error ${groqRes.status}: ${errBody}`)
    }

    const groqData = await groqRes.json()
    const content = groqData.choices?.[0]?.message?.content
    if (!content) throw new Error('Empty response from Groq')

    const result = JSON.parse(content)

    await supabase.from('ai_summaries').insert({
      summary_text: result.summary ?? '',
      pros: result.pros ?? [],
      cons: result.cons ?? [],
      review_count: reviews.length,
    })

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
