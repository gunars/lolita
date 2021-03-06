
class Managed < ApplicationController
  Admin::SystemUser
  Admin::PublicUser
  include Extensions::Cms::Extended
  include Extensions::Cms::HandleRelations
  include Extensions::Cms::HandleMenu
  include Extensions::Cms::List
  include Extensions::Cms::PublicView
  include Extensions::Cms::HandleMetadata
  include Extensions::Cms::HandleParams
  include Extensions::Cms::HandleSpecialFields
  include Extensions::Cms::Reports
  include Extensions::Cms::Crud
  include Extensions::Cms::Callbacks
  include Extensions::Cms::HandleErrors
  include Extensions::Cms::Language if Lolita.config.translation


  # Pēc noklusējuma index dara to pašu ko list, un tādēļ ir atļauta uz 'read' pieejas veidu modulim.
  # Gadījumā kad index dara darbību ar citu pieejas veidu, tad vajadzētu norādīt citu pieejas līmeni
  # Skatīt ApplicationController#allow un Admin::User#can_do_special_action_in_controller?
  # Līdzīgi ir ar open
  def index
    show
  end

  def open
    get_id.to_i>0 ? redirect_to(params.merge(:action=>:update)) : list
  end

  def insert_row
    render :partial=>"/managed/remote_list_row",:locals=>{:fields=>params[:fields],:read_only=>params[:read_only]|| false}
  end
  
  protected

  def after_allow
    handle_params
  end
  
  def my_params
    @my_params
  end
  #Funkcija kas veic darbu ar lokāciju notiekšanu un maiņu
  def update_or_create_location loc={}
    Location.transaction do
      reflection=@object.class.reflections.detect{|name,r| r.class_name=="Location"}
      location=@object.send(reflection.first)
      if location
        location.update_attributes(my_params[:location])
      elsif(my_params[:location][:lat].to_i>0 || loc[:lat].to_i>0)
        location=Location.new(loc||my_params[:location])
        location.mappable=@object
        location.save!
      end  if my_params[:location]
    end
  end
 

  
  #config satur config mainīgo, kas rodas saņemot no apakšklasēm opciju :configuration
  #tas nepieciešams lai nodrošinātu katrai apakšklasie nepieciešamības gadījumā pilnīgi atšķirīgu
  #argumentu reģistrēšanu un apstrādi

  #funkcija apstrādā saņemtos parametrus no apakšklasēm kā arī nosau
  def process_options
    @config=config
    @config[:on_complete]=@config[:on_complete] || "$('#{'#content'}').html(data)"
  end

  
  # Konfigurācijas Hash iespējamās vērtības
  # :parent_name=>Cits vecāka elements pēc kura meklēt, ja ir overwrite vai sessijas mainīgais ar ša'du nosaukumu
  # :overwrite=> Klase pēc kuras meklē ir tā kas norādīt parent_name
  # :tabs - cilnes, kādās ir sadalīts ievades logs, iespējamie noklusētie tipi,
  #   :metadata,
  #   :picture,
  #     :main_image - vai ir lielais attēls
  #     :single - vai ir tikai viens attēls
  #     :create_pdf - vai izveidot pdf failu ar attēlu, jābūt atļautiem arī failiem
  #
  #   :file,
  #   :map,
  #   :translate,
  #   :default - vispārīgs tips paredzēts visām cilnēm
  #   :partial - taba partial forma
  #   :partials - Hash
  #     :before - Array ar partial formām ko renderēt iekš taba pirms galvenā partial
  #     :after - Array ar partial formām ko renderēt iekš taba aiz galvenā partial
  #   Vispārīgā ciļņu konfigurācija
  #   :opened - šī cilne ir atvērat, ja ir vairākas tad pirmais tiks atvērta
  #   :title - cilnes nosaukums
  #   :fields - Hash ar laukiem, vai :default, izmanto kontroliera laukus, vai speciālajām cilnēm
  #             to noklusētie lauki
  #   :type - kāds no tipiem
  #   :in_form - vai nepieciešams postot
  #   :object - post parametru masīva nosaukums, ja :content tips, tad :object, citos gadījumos jānorāda, ja izmanto laukus un nevēlas tos iekļaut iekš object
  #   :form - partial formas nosaukums (piemēram. "translate") vai :default, kas atbilst "object_data"
  # :list - Hash priekš list izsaukuma
  #   :options - ikonas, kuras tiek ievietotas pēdējā kolonnā, (:edit,:destroy)
  #   :sortable - norāda ka varēs kārtot pēc visām kolonnām izņemot Iespējas
  #   :dateformat - norāda datuma formātu, ja list lauka tips ir datetime. Piemēram, "%y/%m/%d %H:%M:%S".
  #   :intro - ievada teksts lapas augšpusē
  #   :include - masīvs ar key=>ārējā atslēga un value=>tabulas_nosaukums, ko iekļaut ja ir padots tāds parametrs
  #              {:blog_id=>"Cms::News"}
  #   :sort_column - kas ir noklusētā kolonna pēc kuras kārtot, vajag norādīt var nenorādīt ja ir :columns
  #                  pēc noklusējuma "created_at"
  #   :sort_direction - kārtošanas veids (augošs - asc vai dilstošs - desc), pēc noklusējuma desc,
  #                     var nenorādīt ja ir :columns
  #   :partial - norāda kādu partial formu ģenerēt, ja nav norādīta tad tiks meklēta atbilstošajā view ar nosaukumu list,
  #              :default būs standarta cms partial vai jebkāds cits
  #   :columns - kollonnas kas tieks attēlotas
  #     :default - norāda, ka pēc noklusējuma pēc šī lauka tiks kārtots, ja ir vairāki norāditi, tad pēc pirmā
  #     :width - kollonas platums px
  #     :title - kolonnas virsraksts, opcionāls, tiks ņemts kolonnas db nosaukums, vai no fields tabula
  #     :link - norāda vai būs edit saite uz elementa rediģēšanu
  #     :field - lauka nosaukums, OBLIGĀTS
  #     :function - lauka vērtības attēlošanai var izsaukt jūsu norādīto funkciju
  #     :sort_direction - kārtošanas veids (asc,desc), pēc noklusējuma asc
  #     :sortable - norāda vai kārtojams, pēc noklusējuma nav, ja norādīts :default tad ir kārtojams
  # :fields - masīvs, katrs masīvas elements ir Hash masīvs, ar šādām
  #           iespējamājām vērtībām:
  #   :type - ievades lauka tikps, kāds no sistēmā definētajiem
  #           (text,textarea,datetime,checkbox,select utt.), skatīt field_helper
  #   :name - lauka nosaukums, reālais nosaukums kāds ir DB,
  #   :title - virsraksts kas parādās pie lauka,
  #   :html - html opcijas, kas, ja nepieciešams, tiek izmantotas lauku ģenerēšanā
  #   :object - objekts, ja nepieciešams cits parametru masīvs nevis params[:object]
  #   :function - tikai priekš custom tipa lauka, funkcija kas atrodas tā tipa
  #               objekta modelī
  #   :args - tikai priekš custom tipa lauka, argumentu masīvs, kas tiks padots
  #           funkcijai
  #   :table - tabulas nosaukums, tiek izmantots dažādiem laukiem, ja laukam nepieciešams
  #            izmantot ārējo tabulu datu iegūšanai
  #   :table_options - opcijas, kas tiek padotas find, izmanto kopā ar table
  #   :titles - String vai Array, tiek izmantots tikai label tipa laukam un iespējams norādīt
  #             speciālajā formātā, sk. field_to_string_simple (field_helper.rb), arī priekš
  #             select tiek izmantots titles, tikai kā options elementu nosaukums
  #   :without_default_value - tikai priekš select tipa, nav tekošā elementa visi options elementi
  #             bez "select" atribūta
  #
  #   :config - tikai priekš date un datetime tipa laukiem, norāda opcijas, kas specifiskas šiem laukiem
  #   :simple - tikai priekš select tipa, norāda, ka opcijas ir padotas un nav jāmeklē
  #   :options - opcijas tikai priekš select, masīvs formā [["nosaukums",id]]
  #   :default_value - tikai select noklusētā vērtība, ja nav atrasta tekošā vērtība, parasti pirmā
  #   :parent_link - tikai select, norāda vai ir saite uz saistīta tipa elementa izveidi
  #   :multiple - tikai select, norāda vai ir multiselect
  #   :unlinked - tikai select, norāda vai elements atradīsies tabulā un elements ja nebūs unlinked nebūs arī multiple
  #   :namespace - tikai select, norāda namespace, ja tas nav tekošais
  #   :include_blank - vai iekļaut tukšo elementu, tikai select
  #   :translate - vai lauks ir tulkojams
  #
  def config
    {} #tikai uzskatāmībai, config jāatrodas iekš katra kontroliera un jāatgriež Hash
  end

  def tab_fields tab
    (tab[:fields] && tab[:fields]==:default ? @config[:fields] : tab[:fields] || [])
  end
  def has_tab_type? name
    @config[:tabs] && @config[:tabs].find{|tab| tab[:type]==name}
  end
  #pašlaik managed var saglabāt tikai speciālo informāciju un informāciju kas atrodas zem
  #masīva params[:object] tādēļ tiek atrasti lauki, kurus vajag tam izmantot
  #citus masīvus, ja tādi ir tad jāsaglabā atsevišķi katrā kontrolierī
  def current_fields
    current_tab=@config[:tabs].find{|tab|
      tab[:object]==:object || tab[:type]==:content
    }
    current_tab[:fields]==:default ? @config[:fields] : current_tab[:fields]
  end
  
  def object
    @config[:object_class]
  end
  
  def self_layout layout=false
    if !all_params
      handle_params
    end
    unless request.xhr? || params[:is_ajax].to_b
      layout='cms/default'
    end
    if @read_only
      {:template=>"managed/read",:layout=>layout}
    else
      {:template=>"managed/create",:layout=>layout}
    end
  end
  
  def set_back_url
    session[:start_links]=[] unless session[:start_links]
    if redirect_step_back?
      session[:start_links].push(params)
    else
      session[:start_links].clear
    end
  end

  def redirect_step_back?
    session[:start_links] && !session[:start_links].empty? && my_params[:set_back_link].to_b
  end

  def redirect_step_back
    next_url=nil
    if session[:start_links] && !session[:start_links].empty?
      while !next_url && !session[:start_links].empty?
        next_url=session[:start_links].pop
        if next_url
          redirect_to next_url
        end
      end
      if !next_url
        redirect_to additional_params
      end
    end
  end

  def on_error existing=false
    #if @object
#      unless existing
#        @new_object_id=picture_id
#      end
      params.delete(:temp_picture_id)
      params.delete(:temp_file_id)
      render self_layout
    #else
    #  render :text=>'Izņēmuma kļūda!',:status=>400
    #end
  end
  
  #gadījumā ja nav nepieciešams saraksts tad tiek parādīts edit logs
  def final_action
    @config[:without_list] ? 'update' : 'list'
  end
  #atbild par novirzīšanu no tekošajām funkcijām
  # parametri: options- Hash
  #   :only_render - renderē tikai layoutut, tas nozīmē, ka par tempaltu ņems to, kas ietilps funkcijas nosaukumā
  #   :layout -  layouta nosaukums
  #   :error - pārvirza uz rendereru, kas atbild par kļūdu atbildi
  #   :step_back - pārvirza uz rendereru, kas atbild par atgriešanos soli atpakaļ
  def redirect_me options={}
    if options[:only_render]
      render options[:layout]
    else
      unless @config[:do_not_redirect]
        if options[:error]
          on_error !@object.new_record?
        elsif options[:step_back]
          redirect_step_back
        else
          redirect_to options[:layout] || additional_params
        end
      end
    end
  end
  
  def redirect_view options={} #FIXME JF: pieliku ||@page, citādi negāja :single=>flase views
    if !@config[:public][:plain] && (!(@object||@page) || options[:error])
      redirect_to home_url
      return
    end
    if options[:only_layout]
      render :layout=>"#{namespace}/public"
    else
      redirection=options[:redirection] || {:action=>options[:action], :controller=>options[:controller]}
      redirect_to redirection
    end
  end

end
